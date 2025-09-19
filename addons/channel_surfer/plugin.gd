@tool
extends EditorPlugin


var dock
var dock_icon

func _enter_tree() -> void:
	dock = preload("res://addons/channel_surfer/scenes/channel_dock.tscn").instantiate()
	dock_icon = preload("res://addons/channel_surfer/assets/channel_icon.png")
	add_control_to_dock(DOCK_SLOT_LEFT_BL, dock)
	set_dock_tab_icon(dock, dock_icon)


func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()
