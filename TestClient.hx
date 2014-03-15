// import flash.events.Event;


class TestClient
{
    var client:Client;

    public function new()
    {

        this.client = new Client();
        this.client.onData = onData;
        this.client.onConnection = onConnection;
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
        trace("msg " + input.readInt16());
    }

    function onConnection()
    {
        trace("CONNNECTED");
        client.connection.output.writeInt16(42);
        trace("length "+ client.connection.output.length);
    }

    static function main()
    {
        new TestClient();
    }
}
