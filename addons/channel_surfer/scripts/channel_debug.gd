@tool
class_name ChannelDebug
extends RichTextLabel


signal alerts_cleared
signal alerts_filled
signal instance_map_changed(changed_map: Dictionary)

var instance_map: Dictionary
var removal_queue: Dictionary
var editor_closing: bool = false

const DEBUG_FONT_COLOR: String = "ff786b"


func _enter_tree() -> void:
    add_to_group(ChannelSurfer.DEBUG_GROUP)


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
        get_tree().call_group(ChannelSurfer.COMPONENT_GROUP, "start_sync")
        instance_map_changed.emit(instance_map)


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

    for scene_uid: String in instance_map.keys():
        var scene_header_added: bool = false
        for instance_log: InstanceLog in instance_map[scene_uid].values():
            var main_channel: String = instance_log.main_channel
            if  main_channel == ChannelSurfer.CHANNEL_PLACEHOLDER or channel_map.has(main_channel):
                var sub_channel: String = instance_log.sub_channel
                if sub_channel == ChannelSurfer.CHANNEL_PLACEHOLDER or channel_map[main_channel].has(sub_channel):
                    continue

            alert_found = true

            if not scene_header_added:
                var scene_name: String = ResourceUID.uid_to_path(scene_uid)
                add_text("%s\n" % scene_name)
                scene_header_added = true

            add_text("\t\tNODE:\t\t%s\n" % instance_log.node_name)
            add_text("\t\tMAIN:\t\t%s\n" % instance_log.main_channel.capitalize())
            add_text("\t\tSUB:\t\t%s\n\n" % instance_log.sub_channel.capitalize())

    if alert_found:
        alerts_filled.emit()
    else:
        alerts_cleared.emit()
