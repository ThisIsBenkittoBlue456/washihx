package washihx.serialization;

interface ISerializer {
    function serialize(object:Dynamic):String;
    function deserialize(string:String):Dynamic;
}