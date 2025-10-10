@tool
extends EditorPlugin


var channel_dock
var channel_dock_icon
var prev_scene_path: String

func _enter_tree() -> void:
	if not ResourceLoader.exists("res://addons/channel_surfer/data/cs_config.tres"):
		var new_config: CSConfig = CSConfig.new()
		ResourceSaver.save(new_config, "res://addons/channel_surfer/data/cs_config.tres")
		await get_tree().process_frame

	channel_dock = preload("res://addons/channel_surfer/scenes/channel_dock.tscn").instantiate()
	channel_dock_icon = preload("res://addons/channel_surfer/assets/channel_icon.png")
	add_control_to_dock(DOCK_SLOT_LEFT_BL, channel_dock)
	set_dock_tab_icon(channel_dock, channel_dock_icon)
	scene_saved.connect(_on_scene_saved)
	EditorInterface.get_file_system_dock().file_removed.connect(_on_file_removed)


func _exit_tree() -> void:
	remove_control_from_docks(channel_dock)
	channel_dock.queue_free()
	scene_saved.disconnect(_on_scene_saved)
	EditorInterface.get_file_system_dock().file_removed.disconnect(_on_file_removed)


func _on_scene_saved(filepath: String) -> void:
	channel_dock.channel_debug.resolve_save_conflict(filepath)


func _on_file_removed(file: String) -> void:
	channel_dock.channel_debug.resolve_delete_conflict(file)
