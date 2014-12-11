class TestServer
{
    var server:anette.Server;

    public function new()
    {
        this.server = new anette.Server("127.0.0.1", 32000);
        this.server.onData = onData;
        this.server.onConnection = onConnection;
        this.server.onDisconnection = onDisconnection;
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
