@tool
extends EditorPlugin


var channel_dock
var channel_dock_icon

func _enter_tree() -> void:
	print("PLUGIN ENTERED TREE")
	channel_dock = preload("res://addons/channel_surfer/scenes/channel_dock.tscn").instantiate()
	channel_dock_icon = preload("res://addons/channel_surfer/assets/channel_icon.png")
	add_control_to_dock(DOCK_SLOT_LEFT_BL, channel_dock)
	set_dock_tab_icon(channel_dock, channel_dock_icon)
	scene_saved.connect(_on_scene_saved)
	scene_changed.connect(_on_scene_changed)


func _ready() -> void:
	print("PLUGIN CALLED READY")


func _exit_tree() -> void:
	remove_control_from_docks(channel_dock)
	channel_dock.queue_free()
	scene_saved.disconnect(_on_scene_saved)
	scene_changed.disconnect(_on_scene_changed)


func _on_scene_saved(filepath: String) -> void:
	channel_dock.channel_debug.check_save(filepath)


func _on_scene_changed(scene_root: Node) -> void:
	if channel_dock.channel_debug.has_surfer(scene_root.scene_file_path):
		# if not scene_root.is_node_ready():
		# 	print("PLUGIN AWAITING READY")
		# 	await scene_root.ready
		# if not scene_root.is_inside_tree():
		# 	print("PLUGIN AWAITING TREE ENTERED")
		# 	await scene_root.tree_entered
		# await get_tree().process_frame
		await get_tree().create_timer(5).timeout
		print("PLUGIN DISPATCHING MAP")
		channel_dock.channel_tree.dispatch_channel_map.call_deferred()
