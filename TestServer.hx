import Server;


class TestServer
{
	var server:Server;

	public function new()
	{
		this.server = new Server("192.168.1.4", 32000);
        this.server.onData = onData;
        this.server.onConnection = onConnection;

		while(true)
		{
			server.pump();
			server.flush();
			Sys.sleep(1/60);
		}
	}

    function onData(input:haxe.io.BytesInput)
    {
        trace("msg " + input.readInt16());
    }

    function onConnection()
    {
        trace("CONNNECTED");
        server.output.writeInt16(42);
    }

	static function main()
	{
		new TestServer();
	}
}
