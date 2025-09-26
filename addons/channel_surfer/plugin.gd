@tool
extends EditorPlugin


var channel_dock
var channel_dock_icon
var prev_scene_path: String

func _enter_tree() -> void:
	channel_dock = preload("res://addons/channel_surfer/scenes/channel_dock.tscn").instantiate()
	channel_dock_icon = preload("res://addons/channel_surfer/assets/channel_icon.png")
	add_control_to_dock(DOCK_SLOT_LEFT_BL, channel_dock)
	set_dock_tab_icon(channel_dock, channel_dock_icon)
	scene_saved.connect(_on_scene_saved)


func _exit_tree() -> void:
	remove_control_from_docks(channel_dock)
	channel_dock.queue_free()
	scene_saved.disconnect(_on_scene_saved)


func _on_scene_saved(filepath: String) -> void:
	channel_dock.channel_debug.erase_scene(filepath)
