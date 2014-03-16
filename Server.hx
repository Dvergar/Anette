import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.BytesBuffer;


// USED BY CONNECTION
class ClientSocket implements ISocket extends BaseSocket
{
    var socket:sys.net.Socket;
    var server:Server;

    public function new(server, socket)
    {
        super();
        this.server = server;
        this.socket = socket;

        // CALLED BY CONNECTION
        this.onData = server.onData;
    }

    public override function send(bytes:haxe.io.Bytes, offset:Int, length:Int)
    {
        socket.output.writeBytes(bytes, offset, length);
    }

    public function connect(ip:String, port:Int){}
    public override function disconnect()
    {
        socket.shutdown(true, true);
        socket.close();

        // CALLING PARENT TO NOTIFY DISCONNECTION :(
        server.sockets.remove(socket);
        server.connections.remove(socket);
        server.onDisconnection();
    }
    public function pump(){}
    public function flush(){}
}


class Server implements ISocket extends BaseSocket
{
    var serverSocket:sys.net.Socket;
    public var sockets:Array<sys.net.Socket>;
    public var connections:Map<sys.net.Socket, Connection> = new Map();
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

                var clientSocket = new ClientSocket(this, newSocket);
                var connection = new Connection(clientSocket);
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
                    // Confusing, rename !
                    connections.get(socket).socket.disconnect();
                }
                catch(ex:haxe.io.Error)
                {
                    if(ex == haxe.io.Error.Blocked) {}
                    
                    if(ex == haxe.io.Error.Overflow)
                    {
                        trace("OVERFLOW");
                    }
                    if(ex == haxe.io.Error.OutsideBounds)
                    {
                        trace("OUTSIDE BOUNDS");
                    }
                }
            }
        }

        // INPUT MESSAGES
        for(conn in connections)
        {
            conn.readDatas();
        }
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
