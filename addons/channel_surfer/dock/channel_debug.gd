@tool
extends Tree


const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const CSUID_TYPE: Resource = preload(CS_PATHS.CSUID_TYPE)
const INSTANCE_TYPE: Resource = preload(CS_PATHS.INSTANCE_TYPE)
const CSUID_KEY: String = "csuid"
const DEV_CHANNEL_PREFIX: String = "cs_dev"
const COMPONENT_GROUP: String = DEV_CHANNEL_PREFIX + "_component"


signal alerts_cleared
signal alerts_filled
signal instance_map_changed(changed_map: Dictionary)

@export var nav_button: Texture2D

const DEBUG_FONT_COLOR: String = "ff786b"

var instance_map: Dictionary
var is_dispatching_edits: bool = false
var edited_current_text: String
var edited_prev_text: String
var edited_parent_text: String


func _ready() -> void:
    hide_root = true
    set_column_expand_ratio(0, 1)
    set_column_expand_ratio(1, 3)
    button_clicked.connect(_on_button_clicked)


func _on_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> void:
    if mouse_button_index == MOUSE_BUTTON_LEFT:
        EditorInterface.open_scene_from_path(item.get_text(1))


func uproot() -> void:
    instance_map.clear()
    update_alerts()

    instance_map_changed.emit(instance_map)


func tag_surfer(surfer_node: ChannelSurfer) -> void:
    if not surfer_node.has_meta(CSUID_KEY):
        surfer_node.set_meta(CSUID_KEY, CSUID_TYPE.generate())
    if not surfer_node.is_in_group(COMPONENT_GROUP):
        surfer_node.add_to_group(COMPONENT_GROUP)


func has_surfer(filepath: String) -> bool:
    var scene_uid: String = ResourceUID.path_to_uid(filepath)
    return instance_map.has(scene_uid)


func resolve_save_conflict(filepath: String) -> void:
    if is_dispatching_edits:
        return

    var scene_uid: String = ResourceUID.path_to_uid(filepath)
    var temp_dir: DirAccess = DirAccess.open(CS_PATHS.TEMP_STORE)

    instance_map.erase(scene_uid)

    if temp_dir:
        if temp_dir.get_files().is_empty():
            get_tree().call_group_flags(
                SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE,
                COMPONENT_GROUP, "report_in", postsave_sync)
            return

        for temp_filename: String in temp_dir.get_files():
            var temp_filepath: String = CS_PATHS.TEMP_STORE + temp_filename
            var temp_packed: PackedScene = ResourceLoader.load(temp_filepath)
            var temp_state: SceneState = temp_packed.get_state()
            var prop_count: int = temp_state.get_node_property_count(0)
            var instance_log: INSTANCE_TYPE = INSTANCE_TYPE.new()
            var surfer_uid: String

            instance_log.node_name = temp_state.get_node_name(0)

            for i in range(prop_count):
                match temp_state.get_node_property_name(0, i):
                    "metadata/csuid":
                        surfer_uid = temp_state.get_node_property_value(0, i)
                    "main":
                        instance_log.main_channel = temp_state.get_node_property_value(0, i).to_snake_case()
                    "sub":
                        instance_log.sub_channel = temp_state.get_node_property_value(0, i).to_snake_case()

            var scene_dict: Dictionary = instance_map.get_or_add(scene_uid, {})

            # Can't think of any way CSUID would be empty at this point
            if surfer_uid.is_empty():
                surfer_uid = CSUID_TYPE.generate()

            scene_dict[surfer_uid] = instance_log
            temp_dir.remove(temp_filepath)

    instance_map_changed.emit(instance_map)


func resolve_delete_conflict(filepath: String) -> void:
    if filepath.ends_with(".tscn"):
        for scene_uid: String in instance_map.keys():
            var int_uid: int = ResourceUID.text_to_id(scene_uid)
            if ResourceUID.has_id(int_uid) and filepath == ResourceUID.get_id_path(int_uid):
                instance_map.erase(scene_uid)
                instance_map_changed.emit(instance_map)
                break


func set_instance_map(new_map: Dictionary) -> void:
    instance_map = new_map


func _edit_instance(surfer_node: ChannelSurfer) -> void:
    if edited_parent_text.is_empty() and surfer_node.main_channel == edited_prev_text:
        surfer_node.main_channel = edited_current_text
    elif surfer_node.main_channel == edited_parent_text and surfer_node.sub_channel == edited_prev_text:
        surfer_node.sub_channel = edited_current_text


func _add_instance(surfer_node: ChannelSurfer) -> void:
    # New scene with new surfer doesn't have scene path yet
    var root_scene_path: String = surfer_node.owner.scene_file_path
    if root_scene_path.is_empty():
        return

    var root_scene_uid: String = ResourceUID.path_to_uid(root_scene_path)

    # Can't think of a way that CSUID would be empty at this point
    if not surfer_node.has_meta(CSUID_KEY) or \
    (instance_map.has(root_scene_uid) and instance_map[root_scene_uid].has(surfer_node.get_meta(CSUID_KEY))):
        surfer_node.set_meta(CSUID_KEY, CSUID_TYPE.generate())

    var surfer_uid: String = surfer_node.get_meta(CSUID_KEY)
    var scene_dict: Dictionary = instance_map.get_or_add(root_scene_uid, {})
    var instance_log: INSTANCE_TYPE = scene_dict.get_or_add(surfer_uid, INSTANCE_TYPE.new())

    instance_log.node_name = surfer_node.name
    instance_log.main_channel = surfer_node.main_channel
    instance_log.sub_channel = surfer_node.sub_channel

    instance_map_changed.emit(instance_map)


func _get_edited_scenes() -> Array:
    var edited_scenes: Array = []

    for scene_uid: String in instance_map.keys():
        var scene_path: String = ResourceUID.uid_to_path(scene_uid)
        if EditorInterface.get_open_scenes().has(scene_path):
            continue

        for instance_log: INSTANCE_TYPE in instance_map[scene_uid].values():
            if (edited_parent_text.is_empty() and instance_log.main_channel == edited_prev_text) or \
            (instance_log.main_channel == edited_parent_text and instance_log.sub_channel == edited_prev_text):
                edited_scenes.append(scene_uid)
                break

    return edited_scenes


func presave_sync(surfer_node: ChannelSurfer) -> void:
    if not is_dispatching_edits:
        return

    _edit_instance(surfer_node)

    EditorInterface.mark_scene_as_unsaved()


func postsave_sync(surfer_node: ChannelSurfer) -> void:
    _add_instance(surfer_node)


func dispatch_channel_edits(current_text: String, prev_text: String, parent_text: String) -> void:
    # WHere to call report_in for edits
    is_dispatching_edits = true

    edited_current_text = current_text
    edited_prev_text = prev_text
    edited_parent_text = parent_text

    var edited_scenes: Array = _get_edited_scenes()
    for scene_uid: String in edited_scenes:
        var scene_path: String = ResourceUID.uid_to_path(scene_uid)
        EditorInterface.open_scene_from_path(scene_path)
        await get_tree().process_frame
        get_tree().call_group(COMPONENT_GROUP, "report_in", presave_sync)
        await get_tree().process_frame
        EditorInterface.save_scene()
        await get_tree().process_frame
        get_tree().call_group(COMPONENT_GROUP, "report_in", postsave_sync)
        await get_tree().process_frame
        EditorInterface.close_scene()

    for scene_path: String in EditorInterface.get_open_scenes():
        EditorInterface.open_scene_from_path(scene_path)
        await get_tree().process_frame
        get_tree().call_group(COMPONENT_GROUP, "report_in", presave_sync)
        await get_tree().process_frame

    is_dispatching_edits = false


func update_alerts(channel_map: Dictionary = {}) -> void:
    clear()
    var alert_found: bool = false
    var debug_root: TreeItem
    var current_scene: TreeItem

    for scene_uid: String in instance_map.keys():
        var scene_header_added: bool = false
        for instance_log: INSTANCE_TYPE in instance_map[scene_uid].values():
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
                current_scene.set_text(0, "SCENE:")
                current_scene.set_text(1, scene_name)
                current_scene.collapsed = true
                current_scene.add_button(1, nav_button)
                scene_header_added = true

            var node_name: String = "%s\n" % instance_log.node_name
            var node_main: String = "%s\n" % instance_log.main_channel.capitalize()
            var node_sub: String = "%s" % instance_log.sub_channel.capitalize()
            var new_node: TreeItem = create_item(current_scene)
            new_node.set_text(0, "NODE:\nMAIN:\nSUB:")
            new_node.set_text(1, node_name + node_main + node_sub)

    if alert_found:
        alerts_filled.emit()
    else:
        alerts_cleared.emit()
