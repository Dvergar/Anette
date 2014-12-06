package anette;


#if flash
class Time
{
    public static inline function now():Float
        return flash.Lib.getTimer() / 1000;
}
#elseif js
class Time
{
    public static inline function now():Float
        return Date.now().getTime() / 1000;
}
#else

class Time
{
    public static inline function now():Float
        return Sys.time();
}
#end