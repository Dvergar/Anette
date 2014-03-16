import anette.Server;


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

		while(true)
		{
			server.pump();
			server.flush();
			Sys.sleep(1/60);
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

        server.output.writeInt16(42);

        var msg = "Hello Client";
        server.output.writeInt8(msg.length);
        server.output.writeString(msg);
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
