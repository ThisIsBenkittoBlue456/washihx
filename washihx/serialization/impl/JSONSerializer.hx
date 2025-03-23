package washihx.serialization.impl;

import haxe.Json;

class JSONSerializer implements ISerializer
{
    public function new()
        {
            /// XDDD
        }   
    
    public function serialize(object:Dynamic):String
        {
            return Json.stringify(object);
        }
    
        public function deserialize(string:String):Dynamic
        {
            return Json.parse(string); 
        }
}