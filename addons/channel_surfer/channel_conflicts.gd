@tool
class_name ChannelConflicts
extends RichTextLabel


signal alerts_cleared
signal alerts_filled

var instance_map: JSON

const DEBUG_FONT_COLOR: String = "ff786b"
const INSTANCE_MAP_PATH: String = "res://addons/channel_surfer/data/instance_map.json"


func _ready() -> void:
    if not FileAccess.file_exists(INSTANCE_MAP_PATH):
        var f: FileAccess = FileAccess.open(INSTANCE_MAP_PATH, FileAccess.WRITE)
        f.store_string("{}")
        f.close()

    var f: FileAccess = FileAccess.open(INSTANCE_MAP_PATH, FileAccess.READ)
    instance_map = JSON.new()
    instance_map.parse(f.get_as_text())
    f.close()
    add_to_group(ChannelSurfer.DEBUG_GROUP)


func add_instance(surfer_node: ChannelSurfer) -> void:
    if surfer_node.has_meta(ChannelSurfer.ID_KEY):
        var root_scene_path: String = surfer_node.owner.scene_file_path
        var root_scene_uid: String = ResourceUID.path_to_uid(root_scene_path)
        var surfer_uid: String = surfer_node.get_meta(ChannelSurfer.ID_KEY)
        var scene_dict: Dictionary = instance_map.data.get_or_add(root_scene_uid, {})

        if surfer_node.main_channel == ChannelSurfer.CHANNEL_PLACEHOLDER:
            scene_dict.erase(surfer_uid)
        else:
            scene_dict[surfer_uid] = {
                "node_name": surfer_node.name,
                "main_channel": surfer_node.main_channel,
                "sub_channel": surfer_node.sub_channel,
            }

        if scene_dict.is_empty():
            instance_map.data.erase(root_scene_uid)

        var f: FileAccess = FileAccess.open(INSTANCE_MAP_PATH, FileAccess.WRITE)
        f.store_string(JSON.stringify(instance_map.data))
        f.close()


func update_alerts(channel_map: JSON) -> void:
    clear()
    var alert_found: bool = false

    for scene_uid: String in instance_map.data.keys():
        var scene_header_added: bool = false
        for instance: Dictionary in instance_map.data[scene_uid].values():
            if channel_map.data.has(instance.main_channel):
                if channel_map.data[instance.main_channel].has(instance.sub_channel):
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
