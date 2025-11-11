@tool
extends TestBase


var checked_out_filepath: String


func before_all() -> Signal:
    checked_out_filepath = _checkout(TEST_PATHS.SURFER_SCENE_PATH)
    await get_tree().process_frame
    EditorInterface.open_scene_from_path(checked_out_filepath)
    await get_tree().process_frame
    EditorInterface.save_scene()
    await get_tree().process_frame
    EditorInterface.close_scene()
    return get_tree().process_frame


func before_each() -> Signal:
    return get_tree().process_frame


func after_each() -> Signal:
    return get_tree().process_frame


func after_all() -> Signal:
    channel_debug.uproot()
    var temp_dir: DirAccess = DirAccess.open("res://")
    temp_dir.remove(checked_out_filepath)
    return get_tree().process_frame


func test_scene_deleted_from_filesystem() -> bool:
    var temp_dir: DirAccess = DirAccess.open("res://")
    temp_dir.remove(checked_out_filepath)
    channel_debug.resolve_delete_conflict(checked_out_filepath)
    await get_tree().process_frame
    return channel_debug.instance_map.is_empty()