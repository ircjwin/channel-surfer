@tool
class_name ChannelDebug
extends RichTextLabel


signal alerts_cleared
signal alerts_filled
signal instance_map_changed(changed_map: Dictionary)

var instance_map: Dictionary

const DEBUG_FONT_COLOR: String = "ff786b"


func _ready() -> void:
    add_to_group(ChannelSurfer.DEBUG_GROUP)


func set_instance_map(new_map: Dictionary) -> void:
    instance_map = new_map


func add_instance(surfer_node: ChannelSurfer) -> void:
    if surfer_node.has_meta(ChannelSurfer.ID_KEY):
        var root_scene_path: String = surfer_node.owner.scene_file_path
        var root_scene_uid: String = ResourceUID.path_to_uid(root_scene_path)
        var surfer_uid: String = surfer_node.get_meta(ChannelSurfer.ID_KEY)
        var scene_dict: Dictionary = instance_map.get_or_add(root_scene_uid, {})

        if surfer_node.main_channel == ChannelSurfer.CHANNEL_PLACEHOLDER:
            scene_dict.erase(surfer_uid)
        else:
            scene_dict[surfer_uid] = {
                "node_name": surfer_node.name,
                "main_channel": surfer_node.main_channel,
                "sub_channel": surfer_node.sub_channel,
            }

        if scene_dict.is_empty():
            instance_map.erase(root_scene_uid)

        instance_map_changed.emit(instance_map)


func update_alerts(channel_map: Dictionary) -> void:
    clear()
    var alert_found: bool = false

    for scene_uid: String in instance_map.keys():
        var scene_header_added: bool = false
        for instance: Dictionary in instance_map[scene_uid].values():
            var main_channel: String = instance["main_channel"]
            if  main_channel == ChannelSurfer.CHANNEL_PLACEHOLDER or channel_map.has(main_channel):
                var sub_channel: String = instance["sub_channel"]
                if sub_channel == ChannelSurfer.CHANNEL_PLACEHOLDER or channel_map[main_channel].has(sub_channel):
                    continue

            alert_found = true

            if not scene_header_added:
                var scene_name: String = ResourceUID.uid_to_path(scene_uid)
                add_text("%s\n" % scene_name)
                scene_header_added = true

            add_text("\t\tNODE:\t\t%s\n" % instance.node_name.to_pascal_case())
            add_text("\t\tMAIN:\t\t%s\n" % instance.main_channel.capitalize())
            add_text("\t\tSUB:\t\t%s\n\n" % instance.sub_channel.capitalize())

    if alert_found:
        alerts_filled.emit()
    else:
        alerts_cleared.emit()
