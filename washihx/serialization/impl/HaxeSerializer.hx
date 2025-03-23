package washihx.serialization.impl;

import haxe.Unserializer;
import haxe.Serializer;

class HaxeSerializer implements ISerializer
{
    public function new()
    {
        /// XDDD
    }   

    public function serialize(object:Dynamic):String
    {
        return Serializer.run(object);
    }

    public function deserialize(string:String):Dynamic
    {
        return Unserializer.run(string);   
    }
}