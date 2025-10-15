@tool
extends EditorPlugin


const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const CHANNEL_DOCK_TYPE: Resource = preload(CS_PATHS.DOCK_TYPE)
const CHANNEL_DOCK_SCENE: PackedScene = preload(CS_PATHS.DOCK_SCENE)
const CHANNEL_DOCK_ICON: Texture2D = preload(CS_PATHS.DOCK_ICON)
const CS_CONFIG_TYPE: Resource = preload(CS_PATHS.CONFIG_TYPE)

var channel_dock: CHANNEL_DOCK_TYPE


func _enter_tree() -> void:
	## Dock should take care of this
	if not ResourceLoader.exists(CS_PATHS.CONFIG_STORE):
		var new_config: CS_CONFIG_TYPE = CS_CONFIG_TYPE.new()
		ResourceSaver.save(new_config, CS_PATHS.CONFIG_STORE)
		await get_tree().process_frame

	channel_dock = CHANNEL_DOCK_SCENE.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BL, channel_dock)
	set_dock_tab_icon(channel_dock, CHANNEL_DOCK_ICON)
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
