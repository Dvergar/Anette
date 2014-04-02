package anette;

import anette.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;


class Connection
{
    public var input:BytesInputEnhanced;
    public var output:BytesOutputEnhanced = new BytesOutputEnhanced();
    public var buffer:BytesBuffer = new BytesBuffer();
    var handler:BaseHandler;  // will call onData, timeout & send methods
    var socket:Socket;  // cached only to pass it to handler.send, not used
    var lastReceive:Float = Time.now();  // used to detect inactivities

    public function new(handler, socket)
    {
        trace("Anette : New Connection");
        this.socket = socket;
        this.handler = handler;
        this.output.bigEndian = true;
    }

    public function readDatas()
    {
        while(buffer.length > 2)
        {
            var offset = 0;

            // GET BUFFER
            var bytes = buffer.getBytes();

            // PUSH BUFFER INTO BYTESINPUT FOR READING
            this.input = new BytesInputEnhanced(bytes);
            input.bigEndian = true;

            var msgLength = input.readInt16();
            if(input.length - input.position < msgLength)
            {
                // SLICE REMAINING BYTES AND PUSH BACK TO BUFFER
                buffer = new BytesBuffer();
                buffer.addBytes(bytes, input.position - 2, buffer.length);
                break;
            }

            // READ EACH MESSAGE
            var msgPos = input.position;
            while(input.position - msgPos < msgLength)
            {
                handler.onData(this);
            }

            // SLICE REMAINING BYTES AND PUSH BACK TO BUFFER
            buffer = new BytesBuffer();
            buffer.addBytes(bytes, input.position, buffer.length);

            // REFRESH TIMER FOR DISCONNECTIONS
            lastReceive = Time.now();
        }

        // DISCONNECT IF CONNECTION NOT ALIVE
        var timeSinceLastSend = Time.now() - lastReceive;
        if(handler.timeout != 0 && timeSinceLastSend > handler.timeout)
        {
            disconnect();
        }
    }

    public function flush()
    {
        // SEND EACH MESSAGE
        if(output.length > 0)
        {
            // GENERATE MESSAGE WITH LENGTH PREFIX
            var outputLength = output.length;

            var msgOutput = new BytesOutputEnhanced(); // Todo getBo static method
            msgOutput.bigEndian = true;                // with bigEndian set
            msgOutput.writeInt16(output.length);
            msgOutput.writeBytes(output.getBytes(), 0,
                                 outputLength);

            // SEND MESSAGE
            // Length cached because getBytes() kill the object :(
            var msgOutputLength = msgOutput.length;

            handler.send(socket, msgOutput.getBytes(), 0, msgOutputLength);

            // RESET OUTPUT
            output = new BytesOutputEnhanced();
            output.bigEndian = true;
        }
    }

    public function disconnect()
    {
        handler.disconnectSocket(socket, this);
    }
}