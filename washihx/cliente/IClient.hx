package washihx.cliente;

import washihx.utils.events.impl.ClientEventManager;

interface IClient
{
    public function enviar(evento:String, ?data:Dynamic):Void;
    public function cerrar():Void;
    public function conectar():Void;
    public function actualizar(timeOut:Float=0):Void;
    public var conexionPerdida:washihx.utils.Error.ClientError->Void;
    public var conexionCerrada:washihx.utils.Error.ClientError->Void;
    public var conexionEstablecida:Void->Void;
    public var eventos:ClientEventManager;
}