package washihx.server;

import washihx.connection.IConnection;

interface IServer
{
    public var enConexionCerrada:String->IConnection->Void; // Listo
    public var enConexionAceptada:String->IConnection->Void; // Listo
    public function start(maxPendingConnection:Int = 1, blocking:Bool = true):Void; // Listo
    private function actualizar(timeOut:Float = 0):Void; // Listo
}