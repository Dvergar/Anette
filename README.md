Anette
======

*Anette is a haxe network library with a simple API :)*

* Supports C++, Neko, Flash and Javascript client-side.
* Supports C++, Neko and Javascript (Node) server-side.

**RoadMap**

* Move Node backend frome *nodejs* to *HaxeFoundation/hxnodejs*.
* UDP sockets.

**Note:** *Client js target will only be served by Node backend for now.*  
**Note2:** *Node backend depends on [nodejs library](https://github.com/dionjwa/nodejs-std), but since it's overriding some of the haxe library classes it only works if you remove or rename the `haxe` folder in `HaxeToolkit\haxe\lib\nodejs\x,x,x\` hoping that it doesn't break your application.*

##Server

**new Server(ip:String, port:Int)**

Creates a TCP server object and bind it to the given host/port.

**server.pump()**

Looks for new messages and put them in the buffer, generally used in a loop.

**server.flush()**

Sends datas from the buffer into the internet tubes, generally used in a loop.

**server.onConnection**

Callback function of type `Connection->Void` when a connection is established.

**server.onDisconnection**

Callback function of type `Connection->Void` when a client disconnects.

**server.onData**

Callback function of type `Connection->Void` when data is received. You should then use `connection.input` to read the datas, input inherits from [`haxe.io.BytesInput`](http://api.haxe.org/haxe/io/BytesInput.html).

example : `server.onData = function(connection:Connection) { connection.input.readString(11) };`

**server.protocol**

Property of type `Protocol`.

There is two built-in protocols: `Prefixed` and `Line`

Protocol used to pack & unpack datas. Note that if you're not using any predefined protocol you'll have to build your own with or without the anette API, otherwise data communication won't be reliable.

* `Prefixed`: Each message is prepended with the length of the message via a short (16bits).
* `Line`: Each message is separated by CR and/or LF bytes.

example: `server.protocol = new Prefixed();`

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

**client.onConnection**

Callback function of type `Connection->Void` when a connection is established.

**client.onDisconnection**

Callback function of type `Connection->Void` when a client disconnects.

**client.onData**

Callback function of type `Connection->Void` when data is received. You should then use `connection.input` to read the datas, input inherits from [`haxe.io.BytesInput`](http://api.haxe.org/haxe/io/BytesInput.html).

example : `client.onData = function(connection:Connection) { connection.input.readString(11) };`

**client.protocol**

Property of type `Protocol`.

There is two built-in protocols: `Prefixed` and `Line`

Protocol used to pack & unpack datas. Note that if you're not using any predefined protocol you'll have to build your own with or without the anette API, otherwise data communication won't be reliable.

* `Prefixed`: Each message is prepended with the length of the message via a short (16bits).
* `Line`: Each message is separated by CR and/or LF bytes.

example: `client.protocol = new Prefixed();`

**client.timeout**

Property of type `Float`, defines the time of inactivity in seconds before the connection is dropped.


##Connection

**connection.output**

Object which inherits from [`haxe.io.BytesOutput`](http://api.haxe.org/haxe/io/BytesOutput.html). This is what you should use to send datas.

example : `connection.output.writeString("hello world");`

**connection.input**

Object which inherits from [`haxe.io.BytesInput`](http://api.haxe.org/haxe/io/BytesInput.html). This is what you should use to read datas.

example : `connection.output.readString(11);`


##Server Example

```Haxe
class TestServer
{
    var server:anette.Server;

    public function new()
    {
        this.server = new anette.Server("127.0.0.1", 32000);
        this.server.onData = onData;
        this.server.onConnection = onConnection;
        this.server.onDisconnection = onDisconnection;
        this.server.protocol = new anette.Protocol.Prefixed();
        this.server.timeout = 10;

        // DIFFERENT TARGETS, DIFFERENT LOOPS
        #if js
        var timer = new haxe.Timer(Std.int(1000 / 60));
        timer.run = loop;
        #else
        while(true) {loop(); Sys.sleep(1/60);}
        #end
    }

    function loop()
    {
        server.pump();
        server.flush();
    }

    function onData(connection:anette.Connection)
    {
        trace("onData " + connection.input.readInt16());

        var msgLength = connection.input.readInt8();
        var msg = connection.input.readString(msgLength);
        trace("onData " + msg);
    }

    function onConnection(connection:anette.Connection)
    {
        trace("CONNNECTION");

        connection.output.writeInt16(42);

        var msg = "Hello Client";
        connection.output.writeInt8(msg.length);
        connection.output.writeString(msg);
    }

    function onDisconnection(connection:anette.Connection)
    {
        trace("DISCONNECTION");
    }

    static function main()
    {
        new TestServer();
    }
}
```


##Client Example

```Haxe
class TestClient
{
    var client:anette.Client;

    public function new()
    {
        this.client = new anette.Client();
        this.client.onData = onData;
        this.client.onConnection = onConnection;
        this.client.onDisconnection = onDisconnection;
        this.client.protocol = new anette.Protocol.Prefixed();
        this.client.timeout = 5;
        this.client.connect("127.0.0.1", 32000);

        #if flash
        flash.Lib.current.stage.addEventListener(flash.events.Event.ENTER_FRAME,
                                                 loop);
        #elseif (cpp||neko)
        while(true) {loop(); Sys.sleep(1 / 60);}
        #elseif js
        var timer = new haxe.Timer(Std.int(1000 / 60));
        timer.run = loop;
        #end
    }

    #if flash
    function loop(event:flash.events.Event)
    #else
    function loop()
    #end
    {
        if(client.connected)
        {
            client.pump();
            client.flush();
        }
    }

    function onData(connection:anette.Connection)
    {
        trace("onData " + connection.input.readInt16());

        var msgLength = connection.input.readInt8();
        var msg = connection.input.readString(msgLength);
        trace("onData " + msg);
    }

    function onConnection(connection:anette.Connection)
    {
        trace("CONNNECTION");
        
        client.connection.output.writeInt16(42);

        var msg = "Hello Server";
        client.connection.output.writeInt8(msg.length);
        client.connection.output.writeString(msg);
    }

    function onDisconnection(connection:anette.Connection)
    {
        trace("DISCONNECTION");
    }

    static function main()
    {
        new TestClient();
    }
}
```