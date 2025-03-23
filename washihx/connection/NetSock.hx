package washihx.connection;

import sys.net.Socket;
import haxe.io.Bytes;
import washihx.utils.Log;

class NetSock 
{
    public var socket:Socket;
    
    public function new(socket:Socket)
    {
        this.socket = socket;
    }

    public function isOpen()
    {
        return socket != null;
    }

    public function writeBytes(bytes:Bytes)
    {
        try
        {
            socket.output.writeBytes(bytes, 0, bytes.length);
        }
        catch(e:Dynamic)
        {
            Log.mensaje(DebugLevel.Errors, "Escritura fallida del Socket:" +e);
            return false;
        }
        return true;
    }
    
    public function readByte(): Int
    {
        return socket.input.readByte();
    }

    public function clean()
    {
        socket = null;
    }

    public function peerToString(): String
    {
        try
        {
        #if!flash
        var peer = this.socket.peer();
        return "[" + peer.host + ":" + peer.port + "]";
        #else
        //See : http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/net/Socket.html#localAddress
        return "Flash socket can't tell the peer host/port unless the adobe Air runtime";
        #end
        }
        catch(e:Dynamic)
        {
            return "[unknown, unknown] (peer data perdido)";
        }
    }
}