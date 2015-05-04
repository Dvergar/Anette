package anette;

import anette.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;




class Prefixed implements IProtocol
{
    public function new() {}

    public inline function readDatas(conn:Connection)
    {
        while(conn.buffer.length > 2)
        {
            var offset = 0;

            // GET BUFFER
            var bufferLength = conn.buffer.length;
            var bytes = conn.buffer.getBytes();

            // PUSH BUFFER INTO BYTESINPUT FOR READING
            conn.input = new BytesInputEnhanced(bytes);
            conn.input.bigEndian = true;

            var msgLength = conn.input.readInt16();
            // trace("msglength " + msgLength);
            if(conn.input.length - conn.input.position < msgLength)
            {
                // SLICE REMAINING BYTES AND PUSH BACK TO BUFFER
                conn.buffer = new BytesBuffer();
                conn.buffer.addBytes(bytes,
                                     conn.input.position - 2,
                                     bufferLength);
                break;
            }
            
            // READ EACH MESSAGE
            var msgPos = conn.input.position;
            while(conn.input.position - msgPos < msgLength)
            {
                conn.input.mark = msgLength;
                conn.handler.onData(conn);
            }

            // SLICE REMAINING BYTES AND PUSH BACK TO BUFFER
            conn.buffer = new BytesBuffer();
            conn.buffer.addBytes(bytes,
                                 conn.input.position,
                                 bufferLength - conn.input.position);

            // REFRESH TIMER FOR DISCONNECTIONS
            conn.lastReceive = Time.now();
        }
    }

    public inline function flush(conn:Connection)
    {
        // SEND EACH MESSAGE
        if(conn.output.length > 0)
        {
            // GENERATE MESSAGE WITH LENGTH PREFIX
            var outputLength = conn.output.length;
            // trace("send " + outputLength);

            var msgOutput = new BytesOutputEnhanced(); // Todo getBo static method
            msgOutput.bigEndian = true;                // with bigEndian set
            msgOutput.writeInt16(conn.output.length);
            msgOutput.writeBytes(conn.output.getBytes(), 0,
                                 outputLength);

            // SEND MESSAGE
            // Length cached because getBytes() kill the object :(
            var msgOutputLength = msgOutput.length;

            conn.handler.send(conn.socket, msgOutput.getBytes(), 0, msgOutputLength);

            // RESET OUTPUT
            conn.output = new BytesOutputEnhanced();
            conn.output.bigEndian = true;
        }
    }
}


class Line implements IProtocol
{
    public function new() {}

    public inline function readDatas(conn:Connection)
    {
        if(conn.buffer.length > 0)
        {
            // GET BUFFER
            var bytes = conn.buffer.getBytes();

            // PUSH BUFFER INTO BYTESINPUT FOR READING
            conn.input = new BytesInputEnhanced(bytes);
            conn.input.bigEndian = true;

            try
            {
                var line = conn.input.readLine();
                conn.input.position = 0;
                conn.handler.onData(conn);
            }
            catch(error:Dynamic)
            {
                trace("EOF " + error);

            }

            // SLICE REMAINING BYTES AND PUSH BACK TO BUFFER
            conn.buffer = new BytesBuffer();
            conn.buffer.addBytes(bytes,
                                 conn.input.position,
                                 conn.buffer.length);

            // REFRESH TIMER FOR DISCONNECTIONS
            conn.lastReceive = Time.now();
        }
    }

    public inline function flush(conn:Connection)
    {
        // SEND EACH MESSAGE
        if(conn.output.length > 0)
        {
            var outputLength = conn.output.length;
            conn.handler.send(conn.socket, conn.output.getBytes(), 0,
                                                       outputLength);

            // RESET OUTPUT
            conn.output = new BytesOutputEnhanced();
            conn.output.bigEndian = true;
        }
    }
}


// USED AS DEFAULT PROTOCOL, NOT SAFE BUT NEEDED FOR PEOPLE ADDING
// A PROTOCOL LAYER ON TOP OF ANETTE, WITHOUT USING ITS API
class NoProtocol implements IProtocol
{
    public function new() {}

    public inline function readDatas(conn:Connection)
    {
        if(conn.buffer.length > 0)
        {
            // GET BUFFER
            var bytes = conn.buffer.getBytes();

            // PUSH BUFFER INTO BYTESINPUT FOR READING
            conn.input = new BytesInputEnhanced(bytes);
            conn.input.bigEndian = true;
            conn.handler.onData(conn);

            // SLICE REMAINING BYTES AND PUSH BACK TO BUFFER
            conn.buffer = new BytesBuffer();

            // REFRESH TIMER FOR DISCONNECTIONS
            conn.lastReceive = Time.now();
        }
    }

    public inline function flush(conn:Connection)
    {
        // SEND EACH MESSAGE
        if(conn.output.length > 0)
        {
            var outputLength = conn.output.length;
            conn.handler.send(conn.socket, conn.output.getBytes(), 0,
                                                       outputLength);

            // RESET OUTPUT
            conn.output = new BytesOutputEnhanced();
            conn.output.bigEndian = true;
        }
    }
}