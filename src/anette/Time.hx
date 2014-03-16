package anette;


#if flash
class Time
{
    public static inline function now():Float
        return flash.Lib.getTimer() / 1000;
}
#else

class Time
{
    public static inline function now():Float
        return Sys.time();
}
#end