import haxe.io.BytesInput;

#if flash
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.ProgressEvent;


class Client implements ISocket extends BaseSocket
{
    var socket:flash.net.Socket = new flash.net.Socket();
    public var connection:Connection;

	public function new()
	{
        super();
		this.connection = new Connection(this);
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
        if(socket.connected)
        {
            try
            {
                while(socket.bytesAvailable > 0)
                	connection.buffer.addByte(socket.readByte());
                
            }
            catch(error:Dynamic)
            {
                trace("Anette : Error " + error);

                this.onDisconnection();
            }

            connection.readDatas();
        }
    }

    public function flush()
    {
        connection.flush();
    }

    public override function send(bytes:haxe.io.Bytes, offset:Int, length:Int)
    {
        socket.writeBytes(bytes.getData(), offset, length);
        socket.flush();
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
}


#elseif (cpp||neko||java)
class Client implements ISocket extends BaseSocket
{
    var socket:sys.net.Socket = new sys.net.Socket();
    public var connection:Connection;

    public function new()
    {
        super();
        this.connection = new Connection(this);
    }

    public function connect(ip:String, port:Int)
    {
        socket = new sys.net.Socket();
        socket.connect(new sys.net.Host(ip), port);
        socket.output.bigEndian = true;
        socket.input.bigEndian = true;
        socket.setBlocking(false);

        onConnection();
    }

    public function pump()
    {
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
                socket.shutdown(true, true);
                socket.close();

                this.onDisconnection();
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

        connection.readDatas();
    }

    public function flush()
    {
        connection.flush();
    }

    public override function disconnect() {};

    public override function send(bytes:haxe.io.Bytes, offset:Int, length:Int)
    {
        socket.output.writeBytes(bytes, offset, length);
    }
}
#end
