@tool
extends EditorPlugin

const AUTOLOADNAME = "Console"


func _enter_tree():
	add_autoload_singleton(AUTOLOADNAME, "res://addons/ConsoleGD/scripts/console.gd")


func _exit_tree():
	remove_autoload_singleton(AUTOLOADNAME)
