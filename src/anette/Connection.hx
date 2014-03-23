package anette;

import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.BytesBuffer;


class Connection
{
    public var output:BytesOutput = new BytesOutput();
    public var buffer:BytesBuffer = new BytesBuffer();
    var handler:BaseHandler;  // will call onData, timeout & send methods
    var socket:Socket;  // cached only to pass it to handler.send, not used
    var lastSend:Float = Time.now();  // used to detect inactivities

    public function new(handler, socket)
    {
        this.socket = socket;
        this.handler = handler;
        this.output.bigEndian = true;
    }

    public function readDatas()
    {

        if(buffer.length > 2)
        {
            var offset = 0;

            // GET BUFFER
            var bytes = buffer.getBytes();

            // PUSH BUFFER INTO BYTESINPUT FOR READING
            var input = new BytesInput(bytes);
            input.bigEndian = true;

            // READ EACH MESSAGE
            while(input.length - input.position > 2)
            {    
                var msgLength = input.readInt16();
                if(input.length >= msgLength)
                {
                    handler.onData(input);
                    offset = 2 + msgLength;
                }
                else
                {
                    break;
                }
            }

            // SLICE REMAINING BYTES AND PUSH BACK TO BUFFER
            buffer = new BytesBuffer();
            buffer.addBytes(bytes, offset, buffer.length);

            // REFRESH TIMER FOR DISCONNECTIONS
            lastSend = Time.now();
        }

        // DISCONNECT IF CONNECTION NOT ALIVE
        var timeSinceLastSend = Time.now() - lastSend;
        if(handler.timeout != 0 && timeSinceLastSend > handler.timeout)
        {
            handler.disconnectSocket(socket);
        }
    }

    public function flush()
    {
        // SEND EACH MESSAGE
        if(output.length > 0)
        {
            // GENERATE MESSAGE WITH LENGTH PREFIX
            var outputLength = output.length;

            var msgOutput = new BytesOutput(); // Todo getBo static method
            msgOutput.bigEndian = true;        // with bigEndian set
            msgOutput.writeInt16(output.length);
            msgOutput.writeBytes(output.getBytes(), 0,
                                 outputLength);

            // SEND MESSAGE
            // Length cached because getBytes() kill the object :(
            var msgOutputLength = msgOutput.length;

            handler.send(socket, msgOutput.getBytes(), 0, msgOutputLength);

            // RESET OUTPUT
            output = new BytesOutput();
            output.bigEndian = true;
        }
    }
}