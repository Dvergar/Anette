package anette;

import haxe.io.BytesInput;


#if (cpp||neko)
import haxe.io.BytesOutput;
import haxe.io.BytesBuffer;


class Server implements ISocket extends BaseHandler
{
    var serverSocket:sys.net.Socket;
    var sockets:Array<sys.net.Socket>;
    var connections:Map<sys.net.Socket, Connection> = new Map();
    public var output:BytesOutput = new BytesOutput();

    public function new(address:String, port:Int)
    {
        super();
        serverSocket = new sys.net.Socket();
        serverSocket.bind(new sys.net.Host(address), port);
        serverSocket.output.bigEndian = true;
        serverSocket.input.bigEndian = true;
        serverSocket.listen(1);
        serverSocket.setBlocking(false);
        sockets = [serverSocket];
    }

    public function connect(ip:String, port:Int)
    {
        throw("Anette : You can't connect as a server");
    }

    public function pump()
    {
        var inputSockets = sys.net.Socket.select(sockets, null, null, 0);
        for(socket in inputSockets.read)
        {
            if(socket == serverSocket)
            {
                var newSocket = socket.accept();
                newSocket.setBlocking(false);
                newSocket.output.bigEndian = true;
                newSocket.input.bigEndian = true;
                sockets.push(newSocket);

                var connection = new Connection(this, newSocket);
                connections.set(newSocket, connection);

                this.onConnection();
            }
            else
            {
                try
                {
                    while(true)
                    {
                        var conn = connections.get(socket);
                        conn.buffer.addByte(socket.input.readByte());
                    }
                }
                catch(ex:haxe.io.Eof)
                {
                    disconnectSocket(socket);
                }
                catch(ex:haxe.io.Error)
                {
                    if(ex == haxe.io.Error.Blocked) {}
                    if(ex == haxe.io.Error.Overflow)
                        trace("OVERFLOW");
                    if(ex == haxe.io.Error.OutsideBounds)
                        trace("OUTSIDE BOUNDS");
                }
            }
        }

        // INPUT MESSAGES
        for(conn in connections)
            conn.readDatas();
    }

    @:allow(anette.Connection)
    override function disconnectSocket(connectionSocket:sys.net.Socket)
    {
        connectionSocket.shutdown(true, true);
        connectionSocket.close();

        // CLEAN UP
        sockets.remove(connectionSocket);
        connections.remove(connectionSocket);
        onDisconnection();
    }

    // CALLED BY CONNECTION
    @:allow(anette.Connection)
    override function send(connectionSocket:sys.net.Socket,
                                  bytes:haxe.io.Bytes,
                                  offset:Int, length:Int)
    {
        connectionSocket.output.writeBytes(bytes, offset, length);
    }

    public function flush()
    {
        // GET BROADCAST BUFFER
        var broadcastLength = this.output.length;
        var broadcastBytes = this.output.getBytes();

        for(socket in connections.keys())
        {
            var conn = connections.get(socket);

            // PUSH BROADCAST BUFFER TO EACH CONNECTION
            if(broadcastLength > 0)
                conn.output.writeBytes(broadcastBytes, 0, broadcastLength);

            conn.flush();
        }

        // RESET BROADCAST BUFFER
        this.output = new BytesOutput();
        this.output.bigEndian = true;
    }
}


#elseif js
import js.Node.NodeNetSocket;
import js.Node.NodeBuffer;


class Server implements ISocket extends BaseHandler
{
    var serverSocket:NodeNetSocket;
    // var sockets:Array<NodeNetSocket>;
    var connections:Map<NodeNetSocket, Connection> = new Map();
    public var output:BytesOutput = new anette.NodeBytesOutput();

    public function new(address:String, port:Int)
    {
        super();
        var nodeNet = js.Node.require('net');
        var server = nodeNet.createServer(function (newSocket)
        {
            var connection = new Connection(this, newSocket);
            connections.set(newSocket, connection); 

            newSocket.on("data", function(buffer) {
                var conn = connections.get(newSocket);
                var bufferLength:Int = cast buffer.length;
                for(i in 0...bufferLength)
                    conn.buffer.addByte(buffer.readInt8(i));
            });

            this.onConnection();

        });
        server.listen(port, address);
    }

    public function connect(ip:String, port:Int)
    {
        throw("Anette : You can't connect as a server");
    }

    public function pump()
    {
        // INPUT MESSAGES
        for(conn in connections)
            conn.readDatas();
    }

    @:allow(anette.Connection)
    override function disconnectSocket(connectionSocket:NodeNetSocket)
    {
        connectionSocket.end();
        connectionSocket.destroy();

        // // CLEAN UP
        connections.remove(connectionSocket);
        onDisconnection();
    }

    // CALLED BY CONNECTION
    @:allow(anette.Connection)
    override function send(connectionSocket:NodeNetSocket,
                                  bytes:haxe.io.Bytes,
                                  offset:Int, length:Int)
    {
        connectionSocket.write(new NodeBuffer(bytes.getData()));
    }

    public function flush()
    {
        // GET BROADCAST BUFFER
        var broadcastLength = this.output.length;
        var broadcastBytes = this.output.getBytes();

        for(socket in connections.keys())
        {
            var conn = connections.get(socket);

            // PUSH BROADCAST BUFFER TO EACH CONNECTION
            if(broadcastLength > 0)
                conn.output.writeBytes(broadcastBytes, 0, broadcastLength);

            conn.flush();
        }

        // RESET BROADCAST BUFFER
        this.output = new BytesOutput();
        this.output.bigEndian = true;
    }
}
#end