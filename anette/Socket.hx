package anette;


#if flash
typedef Socket = flash.net.Socket;
#elseif (cpp||neko||java)
typedef Socket = sys.net.Socket;
#elseif (nodejs && !websocket)
typedef Socket = js.Node.NodeNetSocket;
#elseif (nodejs && websocket)

// Move to WS
// @:jsRequire("ws", "Server")
@:native("WebSocketServer")
extern class WebSocketServer
{
    public function new(?options:{port:Int, host:String}):Void;

    function on(event:String, fn:Dynamic->Void):Void;
    private static function __init__() : Void untyped
    {
    	// trace(js.Node);
        var WebSocketServer = js.Node.require('ws').Server;
    }
}

@:native("WebSocket")
extern class WebSocket
{
    function on(event:String, fn:Dynamic->Void):Void;
    function send(data:Dynamic, opt:{binary:Bool, mask:Bool}):Void;
    function terminate():Void;
}

typedef Socket = WebSocket;

// Client-side (websockets)
#elseif js
typedef Socket = js.html.WebSocket;
#end