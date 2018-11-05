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
        this.server.timeout = 50;

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

    var ids:Int = 0;
    var idmap:Map<anette.Connection, Int> = new Map();

    function onData(connection:anette.Connection)
    {
        trace("onData " + idmap.get(connection) + " : " + connection.input.readInt16());

        var msgLength = connection.input.readInt8();
        var msg = connection.input.readString(msgLength);
        trace("onData " + msg);
    }

    function onConnection(connection:anette.Connection)
    {
        trace("CONNNECTION");
        ids++;
        idmap.set(connection, ids);

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
