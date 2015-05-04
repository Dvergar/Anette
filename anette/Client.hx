package anette;


#if flash
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.ProgressEvent;


class Client implements ISocket.IClientSocket extends BaseHandler
{
    @:isVar public var connected(get, null):Bool;
    public var connection:Connection;
    var socket:flash.net.Socket = new flash.net.Socket();

    public function new()
    {
        super();
        this.connection = new Connection(this, socket);
    }

    public function connect(ip:String, port:Int)
    {
        trace("anette connect");
        socket.connect(ip, port);
        socket.endian = flash.utils.Endian.BIG_ENDIAN;
        socket.addEventListener(Event.CONNECT, onConnect);
        socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError);
        socket.addEventListener(Event.CLOSE, onClose);
        socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
    }

    function onConnect(event:Event)
    {
        this.onConnection(connection);
    }

    public function pump()
    {
        try
        {
            while(socket.bytesAvailable > 0)
                connection.buffer.addByte(socket.readByte());
            
        }
        catch(error:Dynamic)
        {
            trace("Anette : Error " + error);
            disconnectSocket(socket, connection);
        }

        connection.readDatas();
    }

    public function flush()
    {
        connection.flush();
    }

    public function disconnect()
    {
        disconnectSocket(socket, connection);
    }

    @:allow(anette.Connection)
    override function disconnectSocket(socket:flash.net.Socket,
                                       connection:Connection)
    {
        trace("anette disconnection");
        this.onDisconnection(connection);
    }

    @:allow(anette.Connection)
    override function send(connectionSocket:flash.net.Socket,
                                  bytes:haxe.io.Bytes,
                                  offset:Int, length:Int)
    {
        connectionSocket.writeBytes(bytes.getData(), offset, length);
        connectionSocket.flush();
    }

    function onClose(event:Event)
    {
        this.onDisconnection(connection);
    }

    function onError(event:Event)
    {
        trace("Anette : FLASH SOCKET ERROR");
        disconnectSocket(this.socket, connection);
    }

    function onSecError(event:Event)
    {
        trace("Anette : FLASH SOCKET SECURITY ERROR");
    }

    public function get_connected() {return socket.connected;}
}


#elseif (cpp||neko)
class Client implements ISocket.IClientSocket extends BaseHandler
{
    @:isVar public var connected(get, null):Bool;
    public var connection:Connection;
    var socket:sys.net.Socket;

    public function new()
    {
        super();
    }

    public function connect(ip:String, port:Int)
    {
        socket = new sys.net.Socket();

        try
        {
            socket.connect(new sys.net.Host(ip), port);
            this.connected = true;
        }
        catch(error:Dynamic)
        {
            this.onConnectionError(error);
            this.connected = false;
        }

        if(connected)
        {
            socket.output.bigEndian = true;
            socket.input.bigEndian = true;
            socket.setBlocking(false);
            socket.setFastSend(false);
            this.connection = new Connection(this, socket);
            this.onConnection(connection);
        }
    }

    public function pump()
    {
        // Todo : handle "Uncaught exception - std@socket_select"
        var sockets = sys.net.Socket.select([this.socket], null, null, 0);
        if(sockets.read.length > 0)
        {
            try
            {
                while(true)
                {
                    connection.buffer.addByte(socket.input.readByte());
                }
            }
            catch(ex:haxe.io.Eof)
            {
                disconnectSocket(socket, connection);
            }
            catch(ex:haxe.io.Error)
            {
                if(ex == haxe.io.Error.Blocked) {}
                if(ex == haxe.io.Error.Overflow) trace("OVERFLOW");
                if(ex == haxe.io.Error.OutsideBounds) trace("OUTSIDE BOUNDS");
            }
        }
        connection.readDatas();
    }

    public function flush()
    {
        connection.flush();
    }

    public function disconnect()
    {
        disconnectSocket(socket, connection);
    }

    @:allow(anette.Connection)
    override function disconnectSocket(_socket:sys.net.Socket,
                                       connection:Connection)
    {
        _socket.shutdown(true, true);
        _socket.close();
        connected = false;
        this.onDisconnection(connection);
    }

    @:allow(anette.Connection)
    override function send(_socket:sys.net.Socket,
                           bytes:haxe.io.Bytes,
                           offset:Int, length:Int)
    {
        try
        {
            _socket.output.writeBytes(bytes, offset, length);
        }
        catch(error:Dynamic)
        {
            trace("Anette : Send error " + error);
            disconnect();
        }
    }

    public function get_connected() {return connected;}
}

#elseif js
class Client implements ISocket.IClientSocket extends BaseHandler
{
    @:isVar public var connected(get, null):Bool;
    public var connection:Connection;
    var socket:js.html.WebSocket;

    public function new()
    {
        super();
    }

    public function connect(ip:String, port:Int)
    {
        socket = new js.html.WebSocket("ws://" + ip + ":" + port);
        socket.binaryType = "arraybuffer";
        socket.onopen = function(event)
        {  
            this.connection = new Connection(this, socket);
            this.connected = true;
            this.onConnection(connection);
        }

        socket.onmessage = function(event:Dynamic)
        {
            trace("wot");
            var ab:js.html.ArrayBuffer = event.data;
            var d = new js.html.DataView(event.data);

            for(i in 0...ab.byteLength)
                connection.buffer.addByte(d.getUint8(i));
        }

        socket.onclose = function(event) {_disconnectSocket(socket,
                                                            connection);};
        socket.onerror = function(event) {trace("error");};
    }

    public function pump()
    {
        connection.readDatas();
    }

    public function flush()
    {
        connection.flush();
    }

    public function disconnect()
    {
        disconnectSocket(socket, connection);
    }

    function onConnectionError(error:Dynamic)
    {
        trace("Anette : Connection error > " + error);
    }

    @:allow(anette.Connection)
    override function disconnectSocket(_socket:js.html.WebSocket,
                                       connection:Connection)
    {
        _socket.close();
    }

    // BECAUSE .close triggers "onclose" event -> _disconnectSocket
    function _disconnectSocket(_socket:js.html.WebSocket,
                               connection:Connection)
    {
        connected = false;
        onDisconnection(connection);
    }

    @:allow(anette.Connection)
    // TODO : remove offset/length arguments
    override function send(_socket:js.html.WebSocket,
                           bytes:haxe.io.Bytes,
                           offset:Int, length:Int)
    {
        var ba = new js.html.Int8Array(bytes.getData());
        _socket.send(ba);
    }

    public function get_connected() {return connected;}
}
#end
