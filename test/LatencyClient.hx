class LatencyClient
{
    var client:anette.Client;
    var frame:Int = 0;

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

            client.connection.output.writeInt16(frame);
            frames[frame] = haxe.Timer.stamp();
            
            client.pump();
            client.flush();

            frame++;
        }

    }

    var totalLatency:Float = 0;

    function onData(connection:anette.Connection)
    {
        // trace("onData " + connection.input.readInt16());
        var frame = connection.input.readInt16();
        trace("frame " + frame);
        var latency = haxe.Timer.stamp() - frames[frame];
        latency *= 1000;
        trace('latency $latency');

        totalLatency += latency;
        trace('avg latency ' + (totalLatency / frames.length));


        // var msgLength = connection.input.readInt8();
        // var msg = connection.input.readString(msgLength);
        // trace("onData " + msg);
    }

    var frames:Array<Float> = new Array();

    function onConnection(connection:anette.Connection)
    {
        trace("CONNNECTION");

        // for(i in 0...100)
        // {
        //     client.connection.output.writeInt16(42);
        //     client.flush();
        //     times[i] = haxe.Timer.stamp();
        // }
    }

    function onDisconnection(connection:anette.Connection)
    {
        trace("DISCONNECTION");
    }

    static function main()
    {
        new LatencyClient();
    }
}
