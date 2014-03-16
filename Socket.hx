#if flash
typedef Socket = flash.net.Socket;
#elseif (cpp||neko||java)
typedef Socket = sys.net.Socket;
#end