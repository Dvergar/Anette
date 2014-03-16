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
        this.client.connect("192.168.1.4", 32000);

        #if flash
        flash.Lib.current.stage.addEventListener(flash.events.Event.ENTER_FRAME,
                                                loop);
        #elseif (cpp||neko||java)
        while(true)
        {
            loop();
            Sys.sleep(1/60);
        }
        #end
    }

    #if flash
    function loop(ev:flash.events.Event)
    #elseif (cpp||neko||java)
    function loop()
    #end
    {
        client.pump();
        client.flush();
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
