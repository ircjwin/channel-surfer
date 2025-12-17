@tool
extends EditorPlugin


const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const CHANNEL_DOCK_TYPE: Resource = preload(CS_PATHS.DOCK_TYPE)
const CHANNEL_DOCK_SCENE: PackedScene = preload(CS_PATHS.DOCK_SCENE)
const CHANNEL_DOCK_ICON: Texture2D = preload(CS_PATHS.DOCK_ICON)

var channel_dock: CHANNEL_DOCK_TYPE
var plugin: EditorInspectorPlugin


func _enter_tree() -> void:
	channel_dock = CHANNEL_DOCK_SCENE.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BL, channel_dock)
	set_dock_tab_icon(channel_dock, CHANNEL_DOCK_ICON)
	scene_saved.connect(channel_dock._on_scene_saved)
	EditorInterface.get_file_system_dock().file_removed.connect(channel_dock._on_file_removed)
	get_tree().node_added.connect(channel_dock._on_node_added)

	plugin = preload("res://addons/channel_surfer/inspector_plugin.gd").new()
	add_inspector_plugin(plugin)


func _exit_tree() -> void:
	remove_control_from_docks(channel_dock)
	channel_dock.queue_free()
	scene_saved.disconnect(channel_dock._on_scene_saved)
	EditorInterface.get_file_system_dock().file_removed.disconnect(channel_dock._on_file_removed)
	get_tree().node_added.disconnect(channel_dock._on_node_added)

	remove_inspector_plugin(plugin)
