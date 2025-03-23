package washihx.connection.impl;

import haxe.iterators.StringKeyValueIteratorUnicode;
import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Bytes;
import washihx.serialization.impl.HaxeSerializer;
import washihx.serialization.ISerializer;
import washihx.connection.IConnection;
import washihx.server.IServer;
import washihx.server.room.Room;
import washihx.utils.events.impl.ServerEventManager;
import washihx.connection.NetSock;
import haxe.io.Error;
import washihx.utils.Log;

class Connection implements IConnection
{
    private var servidor:IServer;
    public var cnxx:NetSock;
    public var serializer:ISerializer;
    public var events:ServerEventManager;
    public var room:Room;
    public var data:Dynamic;

    public function new()
    {    
    }

    public function clone():IConnection
    {
        return new Connection();
    }

    public function configuracion(_eventos:ServerEventManager, _server:IServer, _serializer:ISerializer = null):Void
    {
        events = _eventos;
        servidor = _server;

        if(_serializer == null)
            this.serializer = new HaxeSerializer();
        else
            serializer = _serializer;
    }

    public function isConnected():Bool { return cnxx !=null && cnxx.isOpen();}
    public function contexto():NetSock { return cnxx;}

    public function putInRoom(newRoom:Room)
    {
        if(newRoom.full)
        {
            return false;
        }
        if (newRoom != null)
        {
            room.onLeave(this);
        }
        room = newRoom;
        newRoom.onJoin(this);

        return true;
    }

    public function enAceptacion(cnxx:NetSock):Void
    {
        this.cnxx = cnxx;
        if(servidor.enConexionAceptada != null)
            servidor.enConexionAceptada("aceptada :"+ this.contexto().peerToString(), this);
    }

    public function enConexion(cnxx:NetSock):Void
    {
        this.cnxx = cnxx;
    }

    public function conexionLost(?reason:String)
    {
        Log.mensaje(DebugLevel.Networking, "Cliente desconectado, código de error:"+reason);
        if(servidor.enConexionCerrada != null)
            servidor.enConexionCerrada(reason, this);
        if(room != null)
        {
            room.onLeave(this);
        }
        if(cnxx != null)
        {
            cnxx.clean();
            this.cnxx = null;
        }
    }

    public function send(event:String, ?data:Dynamic):Bool
    {
        var object = {
            t: event,
            data:data
        }
        var objetoSerializado = serializer.serialize(object);
        var result = cnxx.writeBytes(Bytes.ofString(objetoSerializado + "\r\n"));
        return result;
    }

    public function recibir(line:String)
    {
        var msj = serializer.deserialize(line);
        events.callEvent(msj.t, msj.data, this);
    }

    public function datosRecibidos(input:Input):Void
    {
        var line = "";
        var done:Bool = false;
        var data:String = "";

        while (!done)
        {
            try
            {
                data = input.readLine();
                try
                {
                    recibir(data);
                }
                catch(e:haxe.Exception)
                {
                    Log.mensaje(DebugLevel.Errors | DebugLevel.Networking, "Datos inutilizables de:"+data+"porque :"+e.details());
                    throw Error.Blocked;
                }
                catch(e:Dynamic)
                {
                    Log.mensaje(DebugLevel.Errors | DebugLevel.Networking, "Datos inutilizables de:"+data+"porque :"+e);
                    throw Error.Blocked;
                }
            }
            catch(e:Eof)
            {
                done = true;
            }
            catch(e:Error)
            {
                /// Pos no se xdd
            }
            catch(e:Dynamic)
            {
                Log.mensaje(DebugLevel.Errors | DebugLevel.Networking, "No se puede leer datos ya que:"+e+", haciendo Skip");
            }
        }
    }
}