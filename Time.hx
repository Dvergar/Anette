#if flash
class Time
{
	public static inline function now():Float
		return flash.Lib.getTimer() / 1000;
}
#else
// INILNE ?
class Time
{
	public static inline function now():Float
		return Sys.time();
}
#end