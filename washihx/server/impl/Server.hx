package washihx.server.impl;

import haxe.io.Eof;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import washihx.connection.IConnection;
import washihx.connection.impl.Connection;
import washihx.connection.impl.WebsocketProtocol;
import washihx.connection.NetSock;
import washihx.serialization.ISerializer;
import washihx.serialization.impl.HaxeSerializer;
import washihx.server.room.Room;
import washihx.utils.events.impl.ServerEventManager;
import sys.net.Host;
import sys.net.Socket;
import washihx.utils.Log;

class Server implements IServer
{
    private var leerSockets:Array<Socket>;
    private var clients:Map<Socket, NetSock>;
    private var listener:Socket;
    private var buffer:Bytes;

    public var host(default, null):String;
    public var port(default, null):Int;

    public var blocking(default, set):Bool = true;

    public var enConexionAceptada:String->IConnection->Void;
    public var enConexionCerrada:String->IConnection->Void;

    public var eventos:ServerEventManager;
    public var rooms:Array<Room>;

    private var plantillaNET:IConnection;
    private var serializer:ISerializer;

    public var maximunBufferSize = 10240;
    public var fastSend(default, set) = true;
    function set_fastSend(newValue){ listener.setFastSend(newValue); return newValue;}

    /**
	 * @param	hostname
	 * @param	port
	 * @param	connectionTemplate
	 * @param	_serializer
	 * @param	buffer : set the max read buffer (default = 8Kb) the buffer size is set with buffer * 1024
	 */

    public function new(hostname:String, port:Int, plantillaCoNET:IConnection = null, serializador:ISerializer = null, bufferSize:Int = 8)
    {
        if(hostname == null)
            hostname = Host.localhost();

        this.host = hostname;
        this.port = port;
        this.plantillaNET = plantillaCoNET;

        if(serializador == null)
            serializer = new HaxeSerializer();
        else 
            this.serializer = serializador;

        buffer = Bytes.alloc(1024 * bufferSize);
        listener = new Socket();
        leerSockets = [listener];
        clients = new Map();
        eventos = new ServerEventManager();
        rooms = [];
    }
    
    public function start(maxPendingConnection:Int = 1, blocking:Bool = true)
    {
        Log.mensaje(DebugLevel.Info, "Servidor activado en :"+host+":"+port+"Código despues de server.start, no se ejecutara");
        listen(maxPendingConnection, blocking);
        while(true)
        {
            actualizar();
            Sys.sleep(0.01); // Esperar 1 milisegundo
        }
    }

    public function listen(maxPendingConnection:Int = 1, blocking:Bool = true)
    {
        listener.bind(new Host(host), port);
        listener.listen(1);
        this.blocking = blocking;
    }

    public function actualizar(timeOut:Float = 0)
    {
        var protocolo:IConnection;
        var bytesRecibidos:Int;
        var seleccion = Socket.select(leerSockets, null, null, timeOut);

        for(socket in seleccion.read)
        {
            if(socket == listener)
            {
                var client = listener.accept();
                client.setFastSend(fastSend);
                var netsock = new NetSock(client);
                leerSockets.push(client);
                clients.set(client, netsock);
                client.setBlocking(false);

                if(plantillaNET != null)
                    protocolo = plantillaNET.clone();
                else
                    protocolo = new Connection();

                protocolo.configuracion(this.eventos, this, serializer);
                client.custom = protocolo;
                protocolo.enAceptacion(netsock);
            }
            else
            {
                protocolo = socket.custom;
                var byte:Int = 0;
                bytesRecibidos = 0;
                var len = buffer.length;
                var error = false;
                while(true)
                {
                    if(bytesRecibidos == len - 1)
                    {
                        Log.mensaje(DebugLevel.Warnings, "Atención, el cliente ha excedido el máximo de memoria. Esto podría ser un ataque al servidor. El server puede permitir más memoria con el maximunBufferSize. El Cliente ha sido desconectado");
                        protocolo.conexionLost("Conexión pérdida por exceso de memoria");
                        leerSockets.remove(socket);
                        clients.remove(socket);
                        error = true;
                        break;
                    }
                    Log.mensaje(DebugLevel.Warnings, "Atención, se ha recibido un mensaje con demasiada memoria, aumenta automaticamente el tamaño del buffer"+len+1024);
                    var oldBuffer = buffer;
                    buffer = Bytes.alloc(len + 1024);
                    buffer.blit(0, oldBuffer, 0, len);
                    len = buffer.length;

                    try
                    {
                        byte = socket.input.readByte();
                    }
                    catch(e:Dynamic)
                    {
                        if(Std.isOfType(e, Eof) || e == Eof)
                        {
                            protocolo.conexionLost("Conexión cerrada");
                            leerSockets.remove(socket);
                            clients.remove(socket);
                            error = true;
                            break;
                        }
                        else if(e == haxe.io.Error.Blocked)
                        {
                            break;
                        }
                        else
                        {
                            Log.mensaje(DebugLevel.Warnings, e);
                        }
                    }
                    buffer.set(bytesRecibidos, byte);
                    bytesRecibidos += 1;
                }
                if(bytesRecibidos > 0 && error == false)
                {
                    if(new BytesInput(buffer, 0, bytesRecibidos).readLine()== "GET / HTTP/1.1")
                    {
                        var socket = protocolo.contexto().socket;
                        var netsock = new NetSock(socket);
                        protocolo = new WebsocketProtocol();
                        protocolo.configuracion(this.eventos, this, serializer);
                        socket.custom = protocolo;
                        protocolo.enAceptacion(netsock);
                    }
                    protocolo.datosRecibidos(new BytesInput(buffer, 0, bytesRecibidos));
                }

                if(!protocolo.isConnected())
                {
                    leerSockets.remove(socket);
                    clients.remove(socket);
                    break;
                }
            }
        }
    }

    public function broadcast(event:String, ?data:Dynamic):Bool
    {
        var success = true;
        for(client in clients) 
        {
            if(!cast(client.socket.custom, IConnection).send(event, data))
            {
                success = false;
            }
        }
        return success;
    }

    public function cerrar()
    {
        listener.close();
    }

    private function set_blocking(value:Bool):Bool
    {
        if(blocking == value) return value;
        if(listener != null) listener.setBlocking(value);
        return blocking = value;
    }
}