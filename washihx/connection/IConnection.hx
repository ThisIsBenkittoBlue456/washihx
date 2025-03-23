package washihx.connection;

import washihx.utils.events.impl.ServerEventManager;
import washihx.server.IServer;
import haxe.io.Input;
import washihx.serialization.ISerializer;
import washihx.connection.NetSock;
import washihx.server.room.Room;

interface IConnection
{
    public function clone():IConnection; //Listo
    public function send(event:String, ?data:Dynamic):Bool; //Listo
    public function enConexion(cnxx:NetSock):Void; //Listo
    public function enAceptacion(cnxx:NetSock):Void; //Listo
    public function datosRecibidos(input:Input):Void; //Listo
    public function conexionLost(?reason:String):Void; //Listo
    public function putInRoom(newRoom:Room):Bool; //Listo
    public function contexto():NetSock; //Listo
    public function isConnected():Bool; //Listo
    public function configuracion(_eventos:ServerEventManager, _server:IServer, _serializer:ISerializer = null):Void; //Listo
    public var room:Room;
    public var data:Dynamic;
}