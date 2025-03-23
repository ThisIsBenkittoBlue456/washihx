package washihx.utils.events.impl;

import washihx.utils.Log;

typedef EventFunction = Dynamic->Void;

class ClientEventManager
{
	public var callEvent : String->Dynamic->Void;

	var eventMap:Map<String,EventFunction>;

	public function new()
	{
		eventMap = new Map();
		callEvent = callEventCallback;
	}

	/**
	 * Agrega un evento
	 * Si el evento ya existe, se usará el callback
	 * @param	eventName
	 * @param	event
	 */
	public function on(eventName:String, event:EventFunction)
	{
		eventMap.set(eventName, event);
	}

	/**
	 * Quita un evento si es que existe
	 * @param	eventName
	 */
	public function remove(eventName:String)
	{
		if (eventMap.exists(eventName))
		{
			eventMap.set(eventName,null);
			eventMap.remove(eventName);
		}
	}

	/**
	 * llama un evento si es que existe
	 * Si la llamada asociada es nula no se agregara nada
	 * @param	eventName
	 * @param	data
	 */
	public function callEventCallback(eventName:String, data:Dynamic)
	{
		//Si un evento con ese nombre existe
		if (eventMap.exists(eventName))
		{
			//Ve si el evento viene o no con un sender
			if(eventMap.get(eventName) != null){
				eventMap.get(eventName)(data);
			}else{
				Log.mensaje(DebugLevel.Info | DebugLevel.Networking,"Se recibio el evento de "+eventName+" de todas formas no tiene ningún sender");
			}
		}
	}
}