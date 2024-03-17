extends Object
class_name ConsoleCommand


var _name:String
var _callback:Callable
var _description:String
var _usage_example:String
var _is_cheat:bool


static func generate_setter(command_name:String, object:Object, var_name:String, type:int, descriptin:String = "", is_cheat:bool = false) -> ConsoleCommand:
	var command:ConsoleCommand = ConsoleCommand.new(command_name).set_description(descriptin).set_cheat(is_cheat)
	var callable:Callable
	var value_format:Callable = func(): return '"{name}" = "{value}"'.format({
		"name": command_name,
		"value": str(object.get(var_name)),
		})
	
	#TODO VECTOR2,
	#TODO VECTOR2i,
	#TODO VECTOR3,
	#TODO VECTOR3i,
	
	match type:
		TYPE_STRING:
			callable = func(args:Array):
				if args.size() > 0:
					object.set(var_name, args[0])
				Console.print(value_format.call())
		TYPE_INT:
			callable = func(args:Array):
				if args.size() > 0:
					var string = Console._Utils.get_digit(args[0])
					if string != "":
						object.set(var_name, int(round(float(string))))
				Console.print(value_format.call())
		TYPE_FLOAT:
			callable = func(args:Array):
				if args.size() > 0:
					var string = Console._Utils.get_digit(args[0])
					if string != "":
						object.set(var_name, float(string))
				Console.print(value_format.call())
		TYPE_BOOL:
			callable = func(args:Array):
				if args.size() > 0:
					var string
					if args[0] == "true":
						object.set(var_name, true)
					elif args[0] == "false":
						object.set(var_name, false)
					else:
						string = Console._Utils.get_digit(args[0])
						if string != "":
							object.set(var_name, bool(float(string)))
				Console.print(value_format.call())
		_:
			assert(false, "Unsupported type.")
	
	return command.set_callback(callable)


static func generate_getter(command_name:String, object:Object, var_name:String, descriptin:String = "", is_cheat:bool = false) -> ConsoleCommand:
	var command:ConsoleCommand = ConsoleCommand.new(command_name).set_description(descriptin).set_cheat(is_cheat)
	var value_format:Callable = func(): return '"{name}" = "{value}"'.format({
		"name": command_name,
		"value": str(object.get(var_name)),
		})
	
	return command.set_callback(func(args):
		Console.print(value_format.call())
		)


func _init(name:String):
	set_name(name)


func set_name(value:String) -> ConsoleCommand:
	_name = value.strip_edges().replace(" ", "_")
	return self


func get_name() -> String:
	return _name


func set_callback(value:Callable) -> ConsoleCommand:
	_callback = value
	return self


func get_callback() -> Callable:
	return _callback


func set_description(value:String) -> ConsoleCommand:
	_description = value.strip_edges()
	return self


func get_description()  -> String:
	return _description


func set_cheat(value:bool) -> ConsoleCommand:
	_is_cheat = value
	return self


func is_cheat() -> bool:
		return _is_cheat


func set_usage_example(value:String) -> ConsoleCommand:
	_usage_example = value
	return self


func get_usage_example() -> String:
		return _usage_example
