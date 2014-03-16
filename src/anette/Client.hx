package anette;

import haxe.io.BytesInput;

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
        socket.connect(ip, port);
        socket.endian = flash.utils.Endian.BIG_ENDIAN;
        socket.addEventListener(Event.CONNECT, onConnect);
        socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError);
        socket.addEventListener(Event.CLOSE, onClose);
        socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
    }

    function onConnect(event:Event)
    {
        this.onConnection();
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
            disconnectSocket(socket);
            
        }

        connection.readDatas();
        // }
    }

    public function flush()
    {
        connection.flush();
    }

    public function disconnect()
    {
        disconnectSocket(socket);
    }

    public override function disconnectSocket(socket:flash.net.Socket)
    {
        this.onDisconnection();
    }

    public override function send(connectionSocket:flash.net.Socket,
                                  bytes:haxe.io.Bytes,
                                  offset:Int, length:Int)
    {
        connectionSocket.writeBytes(bytes.getData(), offset, length);
        connectionSocket.flush();
    }

    function onClose(event:Event)
    {
        this.onDisconnection();
    }

    function onError(event:Event)
    {
        trace("Anette : FLASH SOCKET ERROR");
    }

    function onSecError(event:Event)
    {
        trace("Anette : FLASH SOCKET SECURITY ERROR");
    }

    public function get_connected() {return socket.connected;}
}


#elseif (cpp||neko||java)
class Client implements ISocket.IClientSocket extends BaseHandler
{
    @:isVar var connected(get, null):Bool;
    public var connection:Connection;
    var socket:sys.net.Socket;

    public function new()
    {
        super();
    }

    public function connect(ip:String, port:Int)
    {
        socket = new sys.net.Socket();
        socket.output.bigEndian = true;
        socket.input.bigEndian = true;
        socket.setBlocking(false);

        try
        {
            socket.connect(new sys.net.Host(ip), port);
            this.connected = true;
            this.connection = new Connection(this, socket);
            this.onConnection();
        }
        catch(error:Dynamic)
        {
            onConnectionError(error);
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
                disconnectSocket(socket);
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
        disconnectSocket(socket);
    }

    function onConnectionError(error:Dynamic)
    {
        trace("Anette : Connection error > " + error);
    }

    public override function disconnectSocket(_socket:sys.net.Socket)
    {
        _socket.shutdown(true, true);
        _socket.close();
        connected = false;
        this.onDisconnection();
    }

    public override function send(_socket:sys.net.Socket,
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
#end
