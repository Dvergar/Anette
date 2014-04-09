package anette;

import anette.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;


class Connection
{
    public var input:BytesInputEnhanced;
    public var output:BytesOutputEnhanced = new BytesOutputEnhanced();
    public var buffer:BytesBuffer = new BytesBuffer();
    public var handler:BaseHandler;  // will call onData, timeout & send methods
    public var socket:Socket;  // cached only to pass it to handler.send, not used
    public var lastReceive:Float = Time.now();  // used to detect inactivities

    public function new(handler, socket)
    {
        trace("Anette : New Connection");
        this.socket = socket;
        this.handler = handler;
        this.output.bigEndian = true;
    }

    public function readDatas()
    {
        handler.protocol.readDatas(this);

        // DISCONNECT IF CONNECTION NOT ALIVE
        var timeSinceLastSend = Time.now() - lastReceive;
        if(handler.timeout != 0 && timeSinceLastSend > handler.timeout)
        {
            disconnect();
        }
    }

    public function flush()
    {
        handler.protocol.flush(this);
    }

    public function disconnect()
    {
        handler.disconnectSocket(socket, this);
    }
}