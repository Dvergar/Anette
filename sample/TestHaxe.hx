// import js.node.SocketIo;

import js.html.DataView;
import js.html.ArrayBuffer;


@:native("Namespace")
extern class Namespace
{
	public function new(server:IoServer, name:String);
	var name:String;
	var server:IoServer;
	var sockets:Array<IoSocket>;
	var connected:Dynamic;
	var fns:Array<Dynamic>;
	var ids:Int;
	var acks:Dynamic;
	function on(event:String, fn:Dynamic):Void;
}

@:native("Server")
extern class IoServer
{
	// function listen(?server : Dynamic, ?options : Dynamic, ?fn : Dynamic);
	function listen(port:Int):Void;
	function on(event:String, fn:Dynamic):Void;
	var sockets:Namespace;
}

@:native("Socket")
extern class IoSocket
{
	function on(event:String, fn:Dynamic):Void;
}

@:native("WebSocketServer")
extern class WebSocketServer
{
    public function new(?options:{port:Int, host:String}):Void;

	function on(event:String, fn:Dynamic->Void):Void;
    private static function __init__() : Void untyped
	{
        var WebSocketServer = js.Node.require('ws').Server;
	}
}

@:native("WebSocket")
extern class WebSocket
{
	function on(event:String, fn:Dynamic->Void):Void;
	function send(data:Dynamic):Void;
}


class TestHaxe
{
	public function new()
	{
		var sockets = [];

		var wss = new WebSocketServer({port: 32000, host:"192.168.1.4"});
		// trace(new ws.WebSocket());
		// var wss = new ws.Server({port: 32000});
		wss.on('connection', function(ws:WebSocket) {

		    ws.on('message', function(data, flags) {
		        trace('received: ' + Type.typeof(data));
		    });

		    var d = new DataView(new ArrayBuffer(2));
		    // d.setInt16(0, 42);
		    // ws.send(d.buffer);
		    // ws.send("hello");
		    this.onConnection();
		});

		// var io:IoServer = js.Node.require('socket.io').listen(32000, "192.168.1.4");

		// io.on('connection',function(socket){
		//   	trace('connection..');
		// });

		// io.sockets.on('connection', function (socket) {
		// 	trace("lel");
		//   // socket.emit('news', { hello: 'world' });
		//   // socket.on('my other event', function (data) {
		//     // console.log(data);
		//   });
		// });
		// var server = nodeNet.createServer(function (socket) {

		//     // socket.on('connect', function() {
		//         trace("New client!");
		//         // sockets.push(socket);

		//         socket.on("data", function(buffer) {
		//         	trace("data " + buffer.length);
		//         });
		//     // });

		// });
		// server.listen(32000, "192.168.1.4");


		// server.on("connect", function() {trace("connected");});
		// server.on("error", function() {trace("error");});
	}

	static function main()
	{
		new TestHaxe();
	}
}

