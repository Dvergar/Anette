class BaseSocket
{
	@:isVar public var onConnection(get, set):Void->Void;
	@:isVar public var onDisconnection(get, set):Void->Void;
	@:isVar public var onData(get, set):haxe.io.BytesInput->Void;
	@:isVar public var timeout(get, set):Float = 0;

	public function new()
	{
		onConnection = onConnectionDefault;
		onDisconnection = onDisconnectionDefault;
		onData = onDataDefault;
	}

	public function send(bytes:haxe.io.Bytes, offset:Int, length:Int)
	{
		throw("Anette : send method undefined");
	}

	public function disconnect()
	{
		throw("Anette : disconnect method undefined");
	}

    function onDataDefault(input:haxe.io.BytesInput)
    {
    	throw("Anette : onData method undefined");
    }

    function onConnectionDefault()
    {
        trace("Anette : Connection");
    }	

    function onDisconnectionDefault()
    {
        trace("Anette : Disconnection");
    }
}