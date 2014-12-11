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
