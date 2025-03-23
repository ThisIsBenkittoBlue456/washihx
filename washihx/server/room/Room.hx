package washihx.server.room;

import washihx.connection.IConnection;

class Room
{
    public var full:Bool = false;
    public var maxConnections = -1;
    public var connections:Array<IConnection>;

    public function new()
    {
        connections = [];
    }

    public function onLeave(cliente:IConnection)
    {
        connections.remove(cliente);
    }

    public function onJoin(cliente:IConnection)
    {
        if(connections.length < maxConnections || maxConnections == -1)
        {
            connections.push(cliente);
            return true;
        }
        else
        {
            return false;
        }
    }

    public function broadcast(evento:String, ?data:Dynamic)
    {
        var success = true;
        for(cliente in connections)
        {
            if(!cliente.send(evento, data))
            {
                success = false;
            }
        }
        return success;
    }
}