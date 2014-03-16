package anette;


class BaseHandler
{
    public var onConnection:Void->Void;
    public var onDisconnection:Void->Void;
    public var onData:haxe.io.BytesInput->Void;
    public var timeout:Float = 0;

    public function new()
    {
        onConnection = onConnectionDefault;
        onDisconnection = onDisconnectionDefault;
        onData = onDataDefault;
    }

    public function send(socket:Socket,
                         bytes:haxe.io.Bytes,
                         offset:Int, length:Int)
    {
        throw("Anette : send method undefined");
    }

    public function disconnectSocket(socket:Socket)
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