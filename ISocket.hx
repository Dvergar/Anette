interface ISocket
{
	public function connect(ip:String, port:Int):Void;
    public function pump():Void;
    public function flush():Void;
    public function send(bytes:haxe.io.Bytes, offset:Int, length:Int):Void;
}
