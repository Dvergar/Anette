package anette;


#if flash
typedef Socket = flash.net.Socket;
#elseif (cpp||neko||java)
typedef Socket = sys.net.Socket;
#elseif (js)
typedef Socket = js.Node.NodeNetSocket;
#end