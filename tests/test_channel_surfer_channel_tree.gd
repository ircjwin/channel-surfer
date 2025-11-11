@tool
extends TestBase


var channel_surfer: ChannelSurfer
var checked_out_filepath: String


func before_all() -> Signal:
    checked_out_filepath = _checkout(TEST_PATHS.SURFER_SCENE_PATH)
    EditorInterface.open_scene_from_path(checked_out_filepath)
    return get_tree().process_frame


func before_each() -> Signal:
    channel_surfer = EditorInterface.get_edited_scene_root().get_child(0)
    channel_tree._add_tree_item(channel_tree.get_root(), 0)
    return get_tree().process_frame


func after_each() -> Signal:
    channel_surfer.main_channel = ChannelSurfer.CHANNEL_PLACEHOLDER
    EditorInterface.save_scene()
    await get_tree().process_frame
    channel_tree.uproot()
    return get_tree().process_frame


func after_all() -> Signal:
    EditorInterface.close_scene()
    channel_debug.uproot()
    var temp_dir: DirAccess = DirAccess.open("res://")
    temp_dir.remove(checked_out_filepath)
    return get_tree().process_frame


func test_dispatch_map_after_surfer_entered_tree() -> bool:
    EditorInterface.close_scene()
    await get_tree().process_frame
    EditorInterface.open_scene_from_path(checked_out_filepath)
    await get_tree().process_frame
    channel_surfer = EditorInterface.get_edited_scene_root().get_child(0)
    return not channel_surfer.channel_map.is_empty()


func test_dispatch_map_after_channel_added() -> bool:
    channel_tree._add_tree_item(channel_tree.get_root(), 0)
    await get_tree().process_frame
    return len(channel_surfer.channel_map.keys()) == 2


func test_dispatch_map_after_channel_removed() -> bool:
    var tree_item: TreeItem = channel_tree.get_root().get_child(0)
    channel_tree._on_button_clicked(tree_item, 0, 0, MOUSE_BUTTON_LEFT)
    await get_tree().process_frame
    return channel_surfer.channel_map.is_empty()


func test_auto_edit_turned_off() -> bool:
    var auto_update_toggle: bool = channel_settings.auto_update_check_box.button_pressed
    channel_settings.auto_update_check_box.toggled.emit(false)
    channel_surfer.main_channel = channel_tree.NEW_CHANNEL_TEXT
    EditorInterface.save_scene()
    await get_tree().process_frame

    channel_tree.channel_map.erase(channel_tree.NEW_CHANNEL_TEXT)
    channel_tree.channel_map.set("edited_channel", [])
    channel_tree.channel_map_changed.emit(channel_tree.get_channel_map())
    channel_tree.channel_edited.emit("edited_channel", channel_tree.NEW_CHANNEL_TEXT, "")
    await get_tree().process_frame

    channel_settings.auto_update_check_box.toggled.emit(auto_update_toggle)
    return channel_surfer.main_channel == channel_tree.NEW_CHANNEL_TEXT


func test_auto_edit_closed_scene() -> bool:
    var auto_update_toggle: bool = channel_settings.auto_update_check_box.button_pressed
    channel_settings.auto_update_check_box.toggled.emit(true)
    channel_surfer.main_channel = channel_tree.NEW_CHANNEL_TEXT
    EditorInterface.save_scene()
    await get_tree().process_frame

    EditorInterface.close_scene()
    await get_tree().process_frame

    channel_tree.channel_map.erase(channel_tree.NEW_CHANNEL_TEXT)
    channel_tree.channel_map.set("edited_channel", [])
    channel_tree.channel_map_changed.emit(channel_tree.get_channel_map())
    channel_tree.channel_edited.emit("edited_channel", channel_tree.NEW_CHANNEL_TEXT, "")
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame

    EditorInterface.open_scene_from_path(checked_out_filepath)
    await get_tree().process_frame

    channel_surfer = EditorInterface.get_edited_scene_root().get_child(0)
    channel_settings.auto_update_check_box.toggled.emit(auto_update_toggle)
    return channel_surfer.main_channel == "edited_channel"


func test_auto_edit_open_scene() -> bool:
    var auto_update_toggle: bool = channel_settings.auto_update_check_box.button_pressed
    channel_settings.auto_update_check_box.toggled.emit(true)
    channel_surfer.main_channel = channel_tree.NEW_CHANNEL_TEXT
    EditorInterface.save_scene()
    await get_tree().process_frame

    channel_tree.channel_map.erase(channel_tree.NEW_CHANNEL_TEXT)
    channel_tree.channel_map.set("edited_channel", [])
    channel_tree.channel_map_changed.emit(channel_tree.get_channel_map())
    channel_tree.channel_edited.emit("edited_channel", channel_tree.NEW_CHANNEL_TEXT, "")
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame

    channel_surfer = EditorInterface.get_edited_scene_root().get_child(0)
    channel_settings.auto_update_check_box.toggled.emit(auto_update_toggle)
    return channel_surfer.main_channel == "edited_channel"