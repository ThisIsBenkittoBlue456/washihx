package washihx.utils;

import haxe.PosInfos;

@:enum abstract DebugLevel(Int) from Int to Int
{
    var None = 0;
        var Warnings = value(0);
        var Errors = value(1);
        var Info = value(2);
        var Networking = value(3);

    static inline function value(index:Int) return 1 << index; 
}

class Log
{
    public static var debugLevel = DebugLevel.Errors | DebugLevel.Warnings | DebugLevel.Info;
    public static var usePrintIn = #if sys true #else false #end;
    public static var printLevel = true;
    public static var printLocation = true;
    public static function mensaje(level, mensaje, ?infos:PosInfos)
    {
        var l = "";

        if(printLevel)
        {
            if(level & DebugLevel.Warnings != 0) l += "[Warnings]";
            if(level & DebugLevel.Errors != 0) l += "[Errors]";
            if(level & DebugLevel.Info != 0) l += "[Info]";
            if(level & DebugLevel.Networking != 0) l += "[Networking]";
            l+=' ';
        }

        var localizacion = "";
        if(printLocation)
            localizacion = infos.fileName+":"+infos.lineNumber+" : ";
        
        #if sys
            if(debugLevel & level != 0)
                Sys.println(l + localizacion + mensaje);
        #else
            if(debugLevel & level != 0)
                trace(l + localizacion + mensaje);
        #end
    }
}