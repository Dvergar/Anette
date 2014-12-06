package anette;


class BytesInputEnhanced extends haxe.io.BytesInput
{
	public var mark:Int;
	
	public function new(b:haxe.io.Bytes, ?pos:Int = null, ?len:Int = null)
	{
		super(b, pos, len);
	}

	public function readBoolean():Bool
	{
		(readByte() == 0) ? return false : return true;
	}

	public function readUTF():String
	{
		return readString(readInt16());
	}
}

class BytesOutputEnhanced extends haxe.io.BytesOutput
{
	public function new()
	{
		super();
	}

	public function writeBoolean(bool:Bool)
	{
		(bool == true) ? writeByte(1) : writeByte(0);
	}

	public function writeUTF(string:String)
	{
		writeInt16(string.length);
		writeString(string);
	}
}


// interface IBytesOutput
// {
// 	public function writeInt8(x:Int):Void;
// 	public function writeInt16(x:Int):Void;
// 	public function writeString(x:String):Void;
// }


// #if (cpp||neko)
// class BytesDispatcher implements IBytesOutput
// {
// 	var connections:Map<sys.net.Socket, Connection>;

// 	public function new(connections)
// 	{
// 		this.connections = connections;
// 	}

// 	public function writeInt8(x:Int)
// 	{
// 		for(conn in connections) conn.output.writeInt8(x);
// 	}

// 	public function writeInt16(x:Int)
// 	{
// 		trace("zeproaijzer");
// 		for(conn in connections) conn.output.writeInt16(x);
// 	}

// 	public function writeString(x:String)
// 	{
// 		for(conn in connections) conn.output.writeString(x);
// 	}
// }
// #end