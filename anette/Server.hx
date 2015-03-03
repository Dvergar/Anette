package anette;

import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.BytesBuffer;
import anette.Bytes;


#if (cpp||neko)
class Server implements ISocket extends BaseHandler
{
    var serverSocket:sys.net.Socket;
    var sockets:Array<sys.net.Socket>;
    public var connections:Map<sys.net.Socket, Connection> = new Map();

    public function new(address:String, port:Int)
    {
        super();
        serverSocket = new sys.net.Socket();
        serverSocket.bind(new sys.net.Host(address), port);
        // serverSocket.output.bigEndian = true;
        serverSocket.input.bigEndian = true;
        serverSocket.listen(1);
        serverSocket.setBlocking(false);
        serverSocket.setFastSend(false);
        sockets = [serverSocket];
        trace("server " + address + " / " + port);
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
                newSocket.setFastSend(false);
                newSocket.output.bigEndian = true;
                newSocket.input.bigEndian = true;
                sockets.push(newSocket);

                var connection = new Connection(this, newSocket);
                connections.set(newSocket, connection);

                this.onConnection(connection);
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
                    disconnectSocket(socket, connections.get(socket));
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
    override function disconnectSocket(connectionSocket:sys.net.Socket,
                                       connection:Connection)
    {
        // connectionSocket.shutdown(true, true);
        connectionSocket.close();

        // CLEAN UP
        sockets.remove(connectionSocket);
        connections.remove(connectionSocket);
        onDisconnection(connection);
    }

    // CALLED BY CONNECTION
    @:allow(anette.Connection)
    override function send(connectionSocket:sys.net.Socket,
                                  bytes:haxe.io.Bytes,
                                  offset:Int, length:Int)
    {
        try
        {
            connectionSocket.output.writeBytes(bytes, offset, length);
        }
        catch(error:Dynamic)
        {
            trace("Anette : Send error " + error);
            disconnectSocket(connectionSocket, connections.get(connectionSocket));
        }
    }

    public function flush()
    {
        // // GET BROADCAST BUFFER
        // var broadcastLength = this.output.length;
        // var broadcastBytes = this.output.getBytes();

        // for(socket in connections.keys())
        // {
        //     var conn = connections.get(socket);

        //     // PUSH BROADCAST BUFFER TO EACH CONNECTION
        //     if(broadcastLength > 0)
        //         conn.output.writeBytes(broadcastBytes, 0, broadcastLength);

        //     conn.flush();
        // }

        // // RESET BROADCAST BUFFER
        // this.output = new BytesOutput();
        // this.output.bigEndian = true;
        for(socket in connections.keys())
        {
            var conn = connections.get(socket);
            // trace("conn " + conn.output.length);
            conn.flush();
        }
    }
}


#elseif (nodejs && !websocket)
import js.Node.NodeNetSocket;
import js.Node.NodeBuffer;


class Server implements ISocket extends BaseHandler
{
    var serverSocket:NodeNetSocket;
    public var connections:Map<NodeNetSocket, Connection> = new Map();
    public var output:BytesOutput = new BytesOutput();

    public function new(address:String, port:Int)
    {
        super();
        var nodeNet = js.Node.require('net');
        var server = nodeNet.createServer(function(newSocket)
        {
            var watSocket:NodeNetSocket = newSocket;
            watSocket.setNoDelay(true);
            var connection = new Connection(this, newSocket);
            connections.set(newSocket, connection); 

            newSocket.on("data", function(buffer)
            {
                var conn = connections.get(newSocket);
                var bufferLength:Int = cast buffer.length;
                for(i in 0...bufferLength)
                    conn.buffer.addByte(buffer.readUInt8(i));
            });

            this.onConnection(connection);
            newSocket.on("error", function() {trace("error");});
            newSocket.on("close", function()
                                  {
                                      disconnectSocket(newSocket, connection);
                                  });

        });
        trace("port" + port);
        trace("address" + address);
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
    override function disconnectSocket(connectionSocket:NodeNetSocket,
                                       connection:Connection)
    {
        connectionSocket.end();
        connectionSocket.destroy();

        // CLEAN UP
        connections.remove(connectionSocket);
        onDisconnection(connection);
    }

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


#elseif (nodejs && websocket)
import anette.Socket;


class Server implements ISocket extends BaseHandler
{
    var serverSocket:WebSocket;
    var connections:Map<WebSocket, Connection> = new Map();
    public var output:BytesOutput = new BytesOutput();

    public function new(address:String, port:Int)
    {
        super();
        var wss = new WebSocketServer({port: port, host: address});

        wss.on('connection', function(newSocket:WebSocket) {
            var connection = new Connection(this, newSocket);
            connections.set(newSocket, connection); 

            newSocket.on('message', function(message)
            {
                trace("moop");
                var conn = connections.get(newSocket);
                var buffer = new js.Node.NodeBuffer(message);
                var bufferLength:Int = cast buffer.length;

                // Refactor if possible
                for(i in 0...bufferLength)
                    conn.buffer.addByte(buffer.readInt8(i));
            });

            newSocket.on("close", function(o) {trace("close"); _disconnectSocket(newSocket,
                                                                connection);});
            newSocket.on("error", function(o) {trace("error: " + o);});

            this.onConnection(connection);
        });
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
    override function disconnectSocket(connectionSocket:WebSocket,
                                       connection:Connection)
    {
        connectionSocket.terminate();
    }

    // BECAUSE .terminate triggers "close" event -> _disconnectSocket
    function _disconnectSocket(connectionSocket:WebSocket,
                               connection:Connection)
    {
        connections.remove(connectionSocket);
        onDisconnection(connection);
    }

    @:allow(anette.Connection)
    override function send(connectionSocket:WebSocket,
                                  bytes:haxe.io.Bytes,
                                  offset:Int, length:Int)
    {
        connectionSocket.send(bytes.getData(), {binary: true, mask: false});
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