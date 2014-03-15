class BaseSocket
{
	public var onConnection:Void->Void;
	public var onData:haxe.io.BytesInput->Void;

	public function new()
	{
		onConnection = onConnectionDefault;
		onData = onDataDefault;
	}

	public function send(bytes:haxe.io.Bytes, offset:Int, length:Int)
	{
		throw("Send method undefined");
	}

    function onDataDefault(input:haxe.io.BytesInput)
    {
    	throw("onData method undefined");
    }

    function onConnectionDefault()
    {
        throw("onConnection method undefined");
    }	
}