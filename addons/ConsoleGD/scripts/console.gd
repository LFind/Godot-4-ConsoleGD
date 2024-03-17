extends Node

var _commands_list:Array[ConsoleCommand]
var _timestamp:bool

var _console_title:String = ""
var _console_scene:Control = preload("res://addons/ConsoleGD/console_scene.tscn").instantiate()
var _toogle_key:int = KEY_QUOTELEFT

var _pause_tree:bool = true
var _log:String = ""
var enable_cheats:bool
var enable_console:bool:
	set(value):
		enable_console = value
		if enable_console == false and _console_scene._window:
			_console_scene._window.visible = false
var cheats_disabled_warn:String = "Cheats disabled!"

signal input_text(text:String)
signal input_command(command:ConsoleCommand)
signal output_print(text:String)


class _Utils:
	
	static func get_digit(string:String) -> String:
		var reg:RegEx = RegEx.new()
		reg.compile(r"^(\d+[.]\d+|\d+)$")
		var value = reg.search(string)
		if value: return value.subject
		return ""




func _ready():
	get_tree().current_scene.add_sibling.call_deferred(_console_scene)


func print_custom(text:String):
	_log += text
	print_rich(text)
	output_print.emit(text)


func print(text, stacktrace:bool = false, timestamp:bool = true, align:String = "left", color:String = "white", tag:String = "INF"):
	print_custom(format_msg(text, timestamp, align, color, tag) + (_format_stack(get_stack()) if stacktrace else ""))


func printerr(text, stacktrace:bool = false, timestamp:bool = true, align:String = "left", color:String = "#ff3d3d", tag:String = "ERR"):
	print_custom(format_msg(text, timestamp, align, color, tag) + (_format_stack(get_stack()) if stacktrace else ""))


func printwarn(text, stacktrace:bool = false, timestamp:bool = true, align:String = "left", color:String = "#ffe52d", tag:String = "WRN"):
	print_custom(format_msg(text, timestamp, align, color, tag) + (_format_stack(get_stack()) if stacktrace else ""))


func format_msg(text:String, timestamp:bool = true, align:String = "", color:String = "", tag:String = ""):
	text = "[{timestamp}]: " + text if timestamp else text
	text = "[{tag}]" + text if tag != "" else text
	
	text = "[color={color}]" + text if color != "" else text
	text = "[{align}]" + text if align != "" else text
	return text.format({
		"timestamp": timestamp(),
		"text": text,
		"align": align,
		"color": color,
		"tag": tag,
	})


func run_command(name:String, args:Array = []):
	var command = find_command(name)
	var output = name
	for arg in args:
		output += " " + str(arg)
	Console.print("> " + output.rstrip(" "), false, false, "left", "white", "")
	if command:
		if (command.is_cheat() and enable_cheats) or not command.is_cheat():
			command.get_callback().call(args)
		elif command.is_cheat() and not enable_cheats:
			printerr(cheats_disabled_warn)
		input_command.emit(command)


func add_command(command:ConsoleCommand):
	assert(command.get_name() != "", "Missing command's name.")
	assert(command.get_callback().is_valid(), "Invalid callable.")
	_commands_list.append(command)
	_commands_list.sort_custom(func(item_1, item_2):
		return item_1.get_name().naturalnocasecmp_to(item_2.get_name()) < 0
		)


func clear_commnads():
	var old_list = _commands_list
	_commands_list = []
	for i in old_list:
		i.free()


func remove_command(name:String):
	var command = find_command(name)
	_commands_list.erase(command)
	command.free()


func find_command(text:String) -> ConsoleCommand:
	for i in _commands_list:
		if i.get_name() in text.rstrip(" "):
			return i
	return null


func timestamp(pattern:String = ""):
	if pattern == "":
		pattern = "{hh}:{mm}:{ss}"
	
	var time = Time.get_datetime_dict_from_system()
	return pattern.format({
		"hh": str(time["hour"]).pad_zeros(2),
		"mm": str(time["minute"]).pad_zeros(2),
		"ss": str(time["second"]).pad_zeros(2),
	})


func _format_stack(stack:Array) -> String:
	var text:String = ""
	var pattern = "{id} - {line}:{func} > {source}"
	var id:int = 0
	
	stack.remove_at(0)
	
	for item in stack:
		text += "\t" + pattern.format({
			"line": item["line"],
			"func": item["function"],
			"source": item["source"],
			"id": id,
		}) + "\n"
		id += 1
	return "\n\tStacktace:\n" + text.rstrip("\n")


func get_scene() -> Control:
	return _console_scene


func set_pause_tree(value:bool):
	_pause_tree = value


func get_pause_tree() -> bool:
	return _pause_tree


func get_log() -> String:
	return _log


func remove_format(text:String):
	var regex = RegEx.new()
	var lines:Array = text.split()
	regex.compile("^((\\[left\\])|(\\[center\\])|(\\[right\\]))" + "(\\[color=\\w+\\])")
	#regex.compile("^(\\[\\w+(\\s*=\\s*\\w+)*\\])*")
	
	var text_without_tags = regex.sub(text, "", true)
	return text_without_tags


func set_toggle_key(keycode:int):
	_toogle_key = keycode


func get_toggle_key() -> int:
	return _toogle_key


func set_window_title(text:String):
	_console_title = text


func get_window_title() -> String:
	return _console_title


func is_visible() -> bool:
	return get_scene()._window.visible if get_scene()._window else false
