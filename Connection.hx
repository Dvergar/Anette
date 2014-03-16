import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.BytesBuffer;


class Connection
{
    public var id:Int;
    public var input:BytesInput;
    public var output:BytesOutput = new BytesOutput();
    public var buffer:BytesBuffer = new BytesBuffer();
    public var socket:BaseSocket;
    var lastSend:Float;

    public function new(socket)
    {
    	this.socket = socket;
        this.output.bigEndian = true;
        this.lastSend = -1;
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
		            socket.onData(input);
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
        trace("socket timeout " + socket.timeout);
        trace("timeSinceLastSend " + timeSinceLastSend);
        if(socket.timeout != 0 && timeSinceLastSend > socket.timeout)
        {
            trace("pouf");
            socket.disconnect();
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

            socket.send(msgOutput.getBytes(), 0, msgOutputLength);

            // RESET OUTPUT
            output = new BytesOutput();
            output.bigEndian = true;
        }
    }
}