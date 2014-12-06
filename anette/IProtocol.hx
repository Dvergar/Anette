package anette;


interface IProtocol
{
    public function readDatas(conn:Connection):Void;
    public function flush(conn:Connection):Void;
}