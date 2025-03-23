package washihx.cliente.impl;

import washihx.utils.Error.ClientError;
import washihx.serialization.impl.HaxeSerializer;
import washihx.serialization.ISerializer;
import washihx.utils.events.impl.ClientEventManager;
import washihx.connection.NetSock;
import washihx.utils.Log;
import haxe.io.Bytes;
import haxe.io.Input;
import sys.net.Socket;
import sys.net.Host;

class TcpClient implements IClient
{
    public var blocking(default, set):Bool;
    public var conectado:Bool;
    public var cnxx:NetSock;
    public var serializer:ISerializer;
    public var eventos:ClientEventManager;
    private var cliente:Socket;
    private var lecturaSocket:Array<Socket>;

    public var conexionPerdida:washihx.utils.Error.ClientError->Void;
    public var conexionCerrada:washihx.utils.Error.ClientError->Void;
    public var conexionEstablecida:Void->Void;

	public var fastSend(default, set) = true;
	function set_fastSend(newValue){ cliente.setFastSend(newValue); return newValue; }

    var puerto:Int;
    var ip:String;

    public function new(_ip:String, _puerto:Int, _serializador:ISerializer = null, _blocking:Bool = false)
    {
        puerto = _puerto;
        ip = _ip;
        eventos = new ClientEventManager();

        if(_serializador != null)
            serializer = _serializador
        else
            serializer = new HaxeSerializer();

        this.blocking =  _blocking;
    }

    public function conectar()
    {
        Log.mensaje(DebugLevel.Info, "intentando conectar a: "+ip+puerto);
        cliente = new Socket();

        try
        {
            if(ip == null)
                ip = Host.localhost();

            cliente.connect(new Host(ip), puerto);
            cliente.setBlocking(this.blocking);
            conectado = true;
        }
        catch (e:Dynamic)
        {
            conectado = false;
            Log.mensaje(DebugLevel.Errors, "Conexion fallida. Error"+ e);

            if(conexionPerdida != null)
                conexionPerdida(e);
            return;
        }

        lecturaSocket = [cliente];
        cnxx = new NetSock(cliente);
        Log.mensaje(DebugLevel.Info, "Conectado a: "+ip+puerto);

        if(conexionEstablecida != null)
            conexionEstablecida();
    }

    public function actualizar(timeOut:Float = 0)
    {
        if(!conectado) return;
        if(blocking)
            datosRecibidos(cliente.input);
        else
        {
            var seleccion = Socket.select(lecturaSocket, null, null,timeOut);
            for (socket in seleccion.read)
                leerSocket(socket);
        }
    }

    public function recibir(line:String)
    {
        var msg = serializer.deserialize(line);
        eventos.callEvent(msg.t, msg.data);
    }

    public function datosRecibidos(input:Input)
    {
        var line = "";
        try
        {
            line = input.readLine();
        }    
        catch (e:Dynamic)
        {
            perdimosConexion(ClientError.DroppedConnection);
            return;
        }

        recibir(line);
    }

    public function leerSocket(socket:Socket)
    {
        try
        {
            datosRecibidos(socket.input);
        }    
        catch(e:haxe.io.Eof)
        {
            perdimosConexion(ClientError.DroppedConnection);
        }
    }
    
    public function perdimosConexion(?error:washihx.utils.Error.ClientError)
    {
        if(cnxx != null)
        {
            cnxx.clean();
            this.cnxx = null;
        }
        conectado = false;

        if(conexionCerrada != null)
            conexionCerrada(error);
    }

    public function cerrar()
    {
        cliente.close();
        if(cnxx != null)
        {
            cnxx.clean();
            this.cnxx = null;
        }
        cliente = null;
    }

    public function enviar(evento:String, ?data:Dynamic)
    {
        if(isConnected()==false)
        {
            Log.mensaje(DebugLevel.Warnings | DebugLevel.Networking, "no se puede enviar el evento"+evento+"porque el cliente no esta conectado en el server");
            return;
        }

        var object = {
            t:evento,
            data:data
        };

        var objetoSerializado = serializer.serialize(object);
        var resultado = cnxx.writeBytes(Bytes.ofString(objetoSerializado + "\r\n"));
    }

    public function isConnected():Bool {return cnxx != null && cnxx.isOpen();}
    private inline function getConnected():Bool {return cliente != null;}

    private function set_blocking(value:Bool):Bool
    {
        if(blocking == value) return value;
        return blocking = value;
    }
}