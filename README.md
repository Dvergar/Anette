Anette
======

*Anette is a haxe network library with a simple API :)*

* Supports C++, Neko and Javascript (Node) server-side.
* Supports C++, Neko and Flash client-side.

Websockets & UDP sockets will come at some point.

**Note :** *Node backend depends on [nodejs library](https://github.com/dionjwa/nodejs-std), but since it's overriding some of the haxe library classes it only works if you remove or rename the `haxe` folder in `HaxeToolkit\haxe\lib\nodejs\x,x,x\` hoping that it doesn't break your application.*

##Server

**new Server(ip:String, port:Int)**

Creates a TCP server object and bind it to the given host/port.

**server.pump()**

Looks for new messages and put them in the buffer, generally used in a loop.

**server.flush()**

Sends datas from the buffer into the internet tubes, generally used in a loop.

**server.output**

Object of type [`haxe.io.BytesOutput`](http://api.haxe.org/haxe/io/BytesOutput.html). This is what you should use to send datas.

example : `server.output.writeString("hello world");`

**server.onConnection**

Callback function of type `Void->Void` when a connection is established.

**server.onDisconnection**

Callback function of type `Void->Void` when a client disconnects.

**server.onData**

Callback function of type `haxe.io.BytesInput->Void` when data is received. You should then use [`haxe.io.BytesInput`](http://api.haxe.org/haxe/io/BytesInput.html) when passed as argument of the function.

example : `server.onData = function(input:haxe.io.BytesInput) { input.readString(11) };`

**server.timeout**

Property of type `Float`, defines the time of inactivity in seconds before the connection is dropped.


##Client

**new Client()**

Creates a TCP client object.

**client.pump()**

Looks for new messages and put them in the buffer, generally used in a loop.

**client.flush()**

Sends datas from the buffer into the internet tubes, generally used in a loop.

**client.disconnect()**

Drops the connection.

**client.connected**

Property of type `Bool`, returns the state of the connection.

**client.output**

Object of type [`haxe.io.BytesOutput`](http://api.haxe.org/haxe/io/BytesOutput.html). This is what you should use to send datas.

example : `client.output.writeString("hello world");`

**client.onConnection**

Callback function of type `Void->Void` when a connection is established.

**client.onDisconnection**

Callback function of type `Void->Void` when a client disconnects.

**client.onData**

Callback function of type `haxe.io.BytesInput->Void` when data is received. You should then use [`haxe.io.BytesInput`](http://api.haxe.org/haxe/io/BytesInput.html) when passed as argument of the function.

example : `client.onData = function(input:haxe.io.BytesInput) { input.readString(11) };`

**client.timeout**

Property of type `Float`, defines the time of inactivity in seconds before the connection is dropped.


##Server Example

```Haxe
import anette.Server;


class TestServer
{
    var server:Server;

    public function new()
    {
        this.server = new Server("127.0.0.1", 32000);
        this.server.onData = onData;
        this.server.onConnection = onConnection;
        this.server.onDisconnection = onDisconnection;

        while(true) loop();
    }

    function loop()
    {
        server.pump();
        server.flush();
        Sys.sleep(1/60);
    }

    function onConnection()
    {
        trace("CONNNECTION");

        server.output.writeInt16(42);

        var msg = "Hello Client";
        server.output.writeInt8(msg.length);
        server.output.writeString(msg);
    }

    function onData(input:haxe.io.BytesInput)
    {
        trace("onData " + input.readInt16());

        var msgLength = input.readInt8();
        var msg = input.readString(msgLength);
        trace("onData " + msg);
    }

    function onDisconnection()
    {
        trace("DISCONNECTION");
    }

    static function main()
    {
        new TestServer();
    }
}
```


##Client Example (flash)

```Haxe
import anette.Client;


class TestClient
{
    var client:Client;

    public function new()
    {

        this.client = new Client();
        this.client.onData = onData;
        this.client.onConnection = onConnection;
        this.client.onDisconnection = onDisconnection;
        this.client.connect("127.0.0.1", 32000);

        flash.Lib.current.stage.addEventListener(flash.events.Event.ENTER_FRAME,
                                                 loop);
    }

    function loop(ev:flash.events.Event)
    {
        if(client.connected)
        {
            client.pump();
            client.flush();
        }
    }

    function onData(input:haxe.io.BytesInput)
    {
        trace("onData " + input.readInt16());

        var msgLength = input.readInt8();
        var msg = input.readString(msgLength);
        trace("onData " + msg);
    }

    function onConnection()
    {
        trace("CONNNECTION");
        
        client.connection.output.writeInt16(42);

        var msg = "Hello Server";
        client.connection.output.writeInt8(msg.length);
        client.connection.output.writeString(msg);
    }

    function onDisconnection()
    {
        trace("DISCONNECTION");
    }

    static function main()
    {
        new TestClient();
    }
}

```
