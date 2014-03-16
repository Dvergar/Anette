package anette;


interface ISocket
{
    public function connect(ip:String, port:Int):Void;
    public function disconnectSocket(socket:Socket):Void;
    public function pump():Void;
    public function flush():Void;
    public function send(connectionSocket:Socket, bytes:haxe.io.Bytes, offset:Int, length:Int):Void;
}

interface IClientSocket extends ISocket
{
	@:isVar public var connected(get, null):Bool;
	public function get_connected():Bool;
    public function disconnect():Void;
}
