@tool
extends TestBase


var channel_surfer: ChannelSurfer
var checked_out_filepath: String


func before_all() -> Signal:
    checked_out_filepath = _checkout(TEST_PATHS.SURFER_SCENE_PATH)
    EditorInterface.open_scene_from_path(checked_out_filepath)
    channel_surfer = EditorInterface.get_edited_scene_root().get_child(0)
    return get_tree().process_frame


func before_each() -> Signal:
    return get_tree().process_frame


func after_each() -> Signal:
    channel_debug.uproot()
    channel_surfer.main_channel = ChannelSurfer.CHANNEL_PLACEHOLDER
    EditorInterface.save_scene()
    await get_tree().process_frame
    channel_surfer = EditorInterface.get_edited_scene_root().get_child(0)
    return get_tree().process_frame


func after_all() -> Signal:
    EditorInterface.close_scene()
    channel_debug.uproot()
    var temp_dir: DirAccess = DirAccess.open("res://")
    temp_dir.remove(checked_out_filepath)
    return get_tree().process_frame


func test_channel_surfer_save_inside_tree() -> bool:
    channel_surfer.main_channel = "changed_channel"
    EditorInterface.save_scene()
    await get_tree().process_frame

    channel_surfer = EditorInterface.get_edited_scene_root().get_child(0)
    var surfer_scene_uid: String = ResourceUID.path_to_uid(checked_out_filepath)
    var surfer_node_uid: String = channel_surfer.get_meta(channel_debug.CSUID_KEY)
    return channel_debug.instance_map and channel_debug.instance_map[surfer_scene_uid][surfer_node_uid]["main_channel"] == "changed_channel"


func test_channel_surfer_save_outside_tree() -> bool:
    channel_surfer.main_channel = "changed_channel"
    EditorInterface.mark_scene_as_unsaved()
    var temp_checkout: String = _checkout(TEST_PATHS.SENDER_SCENE_PATH)
    EditorInterface.open_scene_from_path(temp_checkout)
    await get_tree().process_frame
    EditorInterface.save_all_scenes()
    await get_tree().process_frame
    EditorInterface.close_scene()
    await get_tree().process_frame

    var temp_dir: DirAccess = DirAccess.open("res://")
    temp_dir.remove(temp_checkout)

    channel_surfer = EditorInterface.get_edited_scene_root().get_child(0)
    var surfer_scene_uid: String = ResourceUID.path_to_uid(checked_out_filepath)
    var surfer_node_uid: String = channel_surfer.get_meta(channel_debug.CSUID_KEY)
    return channel_debug.instance_map and channel_debug.instance_map[surfer_scene_uid][surfer_node_uid]["main_channel"] == "changed_channel"


func test_channel_surfer_fix() -> bool:
    channel_surfer.main_channel = "changed_channel"
    EditorInterface.save_scene()
    await get_tree().process_frame

    channel_surfer = EditorInterface.get_edited_scene_root().get_child(0)
    channel_surfer.main_channel = ChannelSurfer.CHANNEL_PLACEHOLDER
    EditorInterface.save_scene()
    await get_tree().process_frame
    return not channel_debug.get_root() or channel_debug.get_root().get_child_count() == 9