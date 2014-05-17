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