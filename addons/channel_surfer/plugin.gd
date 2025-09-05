@tool
extends EditorPlugin


var dock

func _enter_tree() -> void:
	dock = preload("res://addons/channel_surfer/channel_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BL, dock)


func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.free()
