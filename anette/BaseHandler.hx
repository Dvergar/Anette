package anette;

// import anette.IProtocol;
// import anette.Protocol;


class BaseHandler
{
    public var onData:Connection->Void;
    public var onConnection:Connection->Void;
    public var onConnectionError:Dynamic->Void;
    public var onDisconnection:Connection->Void;
    public var timeout:Float = 0;
    public var protocol:IProtocol;

    public function new()
    {
        onConnection = onConnectionDefault;
        onConnectionError = onConnectionErrorDefault;
        onDisconnection = onDisconnectionDefault;
        onData = onDataDefault;
        protocol = new Protocol.NoProtocol();
    }

    public function send(socket:Socket,
                         bytes:haxe.io.Bytes,
                         offset:Int, length:Int)
    {
        throw("Anette : send method undefined");
    }

    public function disconnectSocket(socket:Socket, connection:Connection)
    {
        throw("Anette : disconnect method undefined");
    }

    function onDataDefault(connection:Connection)
    {
        throw("Anette : onData method undefined");
    }

    function onConnectionDefault(connection:Connection)
    {
        trace("Anette : Connection");
    }

    function onConnectionErrorDefault(error:Dynamic)
    {
        trace("Anette : Connection Error");
    }

    function onDisconnectionDefault(connection:Connection)
    {
        trace("Anette : Disconnection");
    }
}