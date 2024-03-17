extends Control

@onready var _popup_input_help = %PopupInputHelp
@onready var _line_command = %LineCommand
@onready var _window = %Window
@onready var _button_send = %ButtonSend
@onready var _text_box = %TextBox
@onready var _panel_background = %PanelBackground

var _input_help_limit:int = 5
var _input_history:Array[String]
var _window_last_pos:Vector2i
var _window_last_size:Vector2i
var _window_dragging:bool

var _autoscroll_enabled:bool = true
var _already_paused:bool

signal window_moved
signal window_resize


func _ready():
	_load_translation()
	_apply_translation()
	_popup_input_help.popup_window = false
	_window.max_size = get_viewport_rect().size - Vector2(16, 40)
	_line_command.context_menu_enabled = false
	
	focus_entered.connect(func():
		_line_command.release_focus()
		_window.gui_release_focus()
		)
	_popup_input_help.id_pressed.connect(_on_popup_select)
	_popup_input_help.visibility_changed.connect(_on_popup_help_visibility_changed)
	_popup_input_help.window_input.connect(_input)
	_popup_input_help.mouse_exited.connect(_window.grab_focus)
	_window.window_input.connect(_input)
	_text_box.gui_input.connect(_input)
	window_resize.connect(_update_popup_input_help)
	window_moved.connect(_update_popup_input_help)
	_window.focus_entered.connect(release_focus)
	_line_command.text_submitted.connect(_on_command_entered)
	_line_command.text_changed.connect(_on_input_text_changed)
	_line_command.focus_entered.connect(_update_popup_input_help)
	_line_command.focus_exited.connect(_update_popup_input_help)
	_button_send.pressed.connect(func():
		_on_command_entered(_line_command.text)
		)
	
	get_viewport().size_changed.connect(func():
		_window.max_size = get_viewport_rect().size - Vector2(16, 40)
		)
	
	_window.visibility_changed.connect(func():
		_panel_background.visible = _window.visible
		if _window.visible:
			_already_paused = get_tree().paused
			_text_box.text = Console._log
		else:
			_update_popup_input_help()
		get_tree().paused = (Console.get_pause_tree() and _window.visible) or _already_paused
		)
	
	_window.close_requested.connect(func():
		_window.visible = false
		)
	
	Console.output_print.connect(func(text):
		if visible:
			_text_box.text += text
		)
	
	_window.visible = false


func _apply_translation():
	_window.title = tr(_window.title) if Console._console_title == "" else Console._console_title
	_button_send.text = tr(_button_send.text)


func _load_translation():
	var dir_path = "res://addons/ConsoleGD/locale/"
	var files = Array(DirAccess.open(dir_path).get_files()).filter(
		func(file:String):
			return file.ends_with(".translation")
	)
	
	for file in files:
		TranslationServer.add_translation(load(dir_path + file))


func _on_popup_help_visibility_changed():
	if _window.visible:
		_window.grab_focus()
	else:
		_window.gui_release_focus()
	_popup_input_help.position = _line_command.position + Vector2(2, _line_command.global_position.y + (_line_command.size.y)-4) + Vector2(_window.position)


func _input(event):
	if event is InputEventKey:
		if Input.is_key_pressed(Console._toogle_key) and Console.enable_console:
			_window.visible = !_window.visible
	
	if _popup_input_help.visible:
		if event is InputEventKey:
			var id_focus:int = _popup_input_help.get_focused_item()
			if id_focus == -1 and _line_command.has_focus():
				if Input.is_key_pressed(KEY_DOWN):
					_popup_input_help.grab_focus()
					_popup_input_help.set_focused_item(0)
				if Input.is_key_pressed(KEY_UP):
					_popup_input_help.grab_focus()
					_popup_input_help.set_focused_item(_popup_input_help.item_count-1)
			elif _popup_input_help.has_focus() and (
				Input.is_key_pressed(KEY_ESCAPE) or\
				Input.is_key_pressed(KEY_TAB)
			):
				_popup_input_help.set_focused_item(-1)
				_window.grab_focus()
			
			if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER):
					_popup_input_help.id_pressed.emit(id_focus)
		
		if event is InputEventKey or event is InputEventMouseButton:
			_update_popup_input_help()
	
	if _window.visible:
		var scroll_bar = _text_box.get_v_scroll_bar()
		if scroll_bar.value + scroll_bar.page == scroll_bar.max_value:
			_autoscroll_enabled = true
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP) \
			or Input.is_key_pressed(KEY_UP)\
			or Input.is_key_pressed(KEY_PAGEUP)\
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_autoscroll_enabled = false


func _process(delta):
	if not get_tree().paused:
		var camera:Camera2D = get_viewport().get_camera_2d()
		if camera:
			global_position = camera.get_screen_center_position() - camera.get_viewport_rect().size/2/camera.zoom
			scale = Vector2.ONE / camera.zoom
	
	if get_parent().get_child_count() != get_index()+1:
		var parent = get_parent()
		parent.remove_child(self)
		parent.add_child(self)
	
	
	if _window.visible:
		
		#size = get_viewport_rect().size
		_hold_on_screen()
		if _window_last_pos != _window.position:
			window_moved.emit()
			_window_last_pos = _window.position
		
		if _window_last_size != _window.size:
			window_resize.emit()
			_window_last_size = _window.size
		
		_autoscroll()


func _autoscroll():
	if _autoscroll_enabled:
		var scroll_bar = _text_box.get_v_scroll_bar()
		scroll_bar.set_value(scroll_bar.max_value)


func _hold_on_screen():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	
	var weight:float = 0.35
	var limit_right:int = int(get_viewport_rect().size.x - _window.size.x - 10)
	var limit_left:int = 10
	var limit_up:int = 30
	var limit_bottom:int = int(get_viewport_rect().size.y)
	
	if _window.position.x < limit_left:
		_window.position.x = lerp(_window.position.x, limit_left, weight)
	elif _window.position.x > limit_right:
		_window.position.x = lerp(_window.position.x, limit_right, weight)
	
	if _window.position.y < limit_up:
		_window.position.y = lerp(_window.position.y, limit_up, weight)
	elif _window.position.y > limit_bottom:
		_window.position.y = lerp(_window.position.y, limit_bottom, weight)


func _on_input_text_changed(text:String):
	_update_popup_input_help()
	_window.grab_focus()


func _update_popup_input_help():
	var items:Array = []
	var text = _line_command.text
	var input_clear = len(text) == 0
	
	_popup_input_help.clear()
	if input_clear:
		items.append_array(_input_history)
		items.reverse()
		
	else:
		for i in Console._commands_list:
			if items.size() >= _input_help_limit: break
			if text in i.get_name():
				items.append(i)
	
	for i in range(items.size()):
		var item = items[i]
		if input_clear:
			if _popup_input_help.item_count >= _input_help_limit: break
			_popup_input_help.add_item(item)
		else:
			_popup_input_help.add_item((item.get_name() + " " + item.get_usage_example()).strip_edges())
			_popup_input_help.set_item_metadata(i, item.get_name())
	
	var visible_popup = _line_command.has_focus() and items.size() > 0 and _window.visible
	_popup_input_help.visible = visible_popup
	_update_popup_input_help_transform()


func _update_popup_input_help_transform():
	if _popup_input_help.visible:
			_popup_input_help.position = _line_command.position + Vector2(2, _line_command.global_position.y + (_line_command.size.y)-4) + Vector2(_window.position)
			_popup_input_help.size = Vector2(4 + _line_command.size.x, (19*_popup_input_help.item_count)+8)


func _on_popup_select(id:int):
	if id == -1: return
	var text = _popup_input_help.get_item_metadata(id)
	if not text:
		text = _popup_input_help.get_item_text(id)
	_line_command.set_text(text)
	_line_command.grab_focus()
	_line_command.set_caret_column(len(text)) 


func _on_command_entered(text:String):
	text = text.strip_edges()
	Console.input_text.emit(text)
	
	if text != "":
		_input_history.erase(text)
		_input_history.append(text)
	
	var args = text.split(" ")
	var name_command = args[0]
	args.remove_at(0)
	Console.run_command(name_command,args)
	
	_line_command.set_text("")
	_update_popup_input_help()



