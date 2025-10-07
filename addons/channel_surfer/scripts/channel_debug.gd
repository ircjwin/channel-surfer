@tool
class_name ChannelDebug
extends Tree


signal alerts_cleared
signal alerts_filled
signal instance_map_changed(changed_map: Dictionary)

@export var nav_button: Texture2D

var instance_map: Dictionary
var removal_queue: Dictionary
var editor_closing: bool = false

const DEBUG_FONT_COLOR: String = "ff786b"


func _enter_tree() -> void:
    add_to_group(ChannelSurfer.DEBUG_GROUP)


func _ready() -> void:
    hide_root = true

    button_clicked.connect(_on_button_clicked)


func _on_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> void:
    if mouse_button_index == MOUSE_BUTTON_LEFT:
        EditorInterface.open_scene_from_path(item.get_text(0))


func has_surfer(filepath: String) -> bool:
    var scene_uid: String = ResourceUID.path_to_uid(filepath)
    return instance_map.has(scene_uid)


func erase_scene(filepath: String) -> void:
    var scene_uid: String = ResourceUID.path_to_uid(filepath)
    instance_map.erase(scene_uid)
    instance_map_changed.emit(instance_map)


func set_instance_map(new_map: Dictionary) -> void:
    instance_map = new_map


func edit_instance(new_name: String, old_name: String, parent_name: String) -> void:
    var is_changed: bool = false
    for scene_dict: Dictionary in instance_map.values():
        for instance_log: InstanceLog in scene_dict.values():
            if parent_name:
                if instance_log.main_channel == parent_name and instance_log.sub_channel == old_name:
                    instance_log.sub_channel = new_name
                    instance_log.is_edited = true
                    is_changed = true
            else:
                if instance_log.main_channel == old_name:
                    instance_log.main_channel = new_name
                    instance_log.is_edited = true
                    is_changed = true
    if is_changed:
        instance_map_changed.emit(instance_map)

        for scene_uid: String in instance_map.keys():
            var scene_path: String = ResourceUID.uid_to_path(scene_uid)
            print("\nLOADING SCENE: %s" % scene_path)
            EditorInterface.open_scene_from_path(scene_path)
            await get_tree().process_frame
            await get_tree().process_frame
            EditorInterface.save_scene()
            await get_tree().process_frame
            EditorInterface.close_scene()
        # get_tree().call_group(ChannelSurfer.COMPONENT_GROUP, "start_sync")


func _sync_instance(surfer_node: ChannelSurfer, instance_log: InstanceLog) -> InstanceLog:
    instance_log.node_name = surfer_node.name

    if instance_log.is_edited:
        surfer_node.main_channel = instance_log.main_channel
        surfer_node.sub_channel = instance_log.sub_channel
        instance_log.is_edited = false
    else:
        instance_log.main_channel = surfer_node.main_channel
        instance_log.sub_channel = surfer_node.sub_channel

    surfer_node.end_sync()

    return instance_log


func add_instance(surfer_node: ChannelSurfer) -> void:
    print("%s WAS RECEIVED BY DEBUG" % surfer_node.name)
    if surfer_node.has_meta(ChannelSurfer.ID_KEY):
        var root_scene_path: String = surfer_node.owner.scene_file_path
        var root_scene_uid: String = ResourceUID.path_to_uid(root_scene_path)
        var surfer_uid: String = surfer_node.get_meta(ChannelSurfer.ID_KEY)
        var scene_dict: Dictionary = instance_map.get_or_add(root_scene_uid, {})
        var instance_log: InstanceLog = scene_dict.get_or_add(surfer_uid, InstanceLog.new())
        scene_dict[surfer_uid] = _sync_instance(surfer_node, instance_log)

        instance_map_changed.emit(instance_map)


func update_alerts(channel_map: Dictionary) -> void:
    clear()
    var alert_found: bool = false
    var debug_root: TreeItem
    var current_scene: TreeItem

    for scene_uid: String in instance_map.keys():
        var scene_header_added: bool = false
        for instance_log: InstanceLog in instance_map[scene_uid].values():
            var main_channel: String = instance_log.main_channel
            if  main_channel == ChannelSurfer.CHANNEL_PLACEHOLDER or channel_map.has(main_channel):
                var sub_channel: String = instance_log.sub_channel
                if sub_channel == ChannelSurfer.CHANNEL_PLACEHOLDER or channel_map[main_channel].has(sub_channel):
                    continue

            if not alert_found:
                debug_root = create_item()
                alert_found = true

            if not scene_header_added:
                var scene_name: String = ResourceUID.uid_to_path(scene_uid)
                current_scene = create_item(debug_root)
                current_scene.set_text(0, scene_name)
                current_scene.collapsed = true
                current_scene.add_button(0, nav_button)
                scene_header_added = true

            var node_name: String = "NODE:  %s\n" % instance_log.node_name
            var node_main: String = "MAIN:   %s\n" % instance_log.main_channel.capitalize()
            var node_sub: String =  "SUB:      %s\n" % instance_log.sub_channel.capitalize()
            var new_node: TreeItem = create_item(current_scene)
            new_node.set_text(0, node_name + node_main + node_sub)

    if alert_found:
        alerts_filled.emit()
    else:
        alerts_cleared.emit()
