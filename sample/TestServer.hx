import anette.Server;
import anette.Connection;


class TestServer
{
    var server:Server;

    public function new()
    {
        this.server = new Server("192.168.1.4", 32000);
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

    function onData(connection:Connection)
    {
        trace("onData " + connection.input.readInt16());

        var msgLength = connection.input.readInt8();
        var msg = connection.input.readString(msgLength);
        trace("onData " + msg);
    }

    function onConnection(connection:Connection)
    {
        trace("CONNNECTION");

        server.output.writeInt16(42);

        var msg = "Hello Client";
        server.output.writeInt8(msg.length);
        server.output.writeString(msg);
    }

    function onDisconnection(connection:Connection)
    {
        trace("DISCONNECTION");
    }

    static function main()
    {
        new TestServer();
    }
}
