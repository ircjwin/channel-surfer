@tool
extends TestBase


const TEST_PATHS: Resource = preload("res://tests/core/test_paths.gd")

var channel_surfer: ChannelSurfer


func before_all() -> Signal:
    EditorInterface.open_scene_from_path(TEST_PATHS.TEST_SCENE_PATH)
    channel_surfer = EditorInterface.get_edited_scene_root().get_child(0)
    return get_tree().process_frame


func before_each() -> Signal:
    channel_tree._add_tree_item(channel_tree.get_root(), 0)
    await get_tree().process_frame

    channel_surfer.main_channel = channel_tree.NEW_CHANNEL_TEXT
    EditorInterface.save_scene()
    return get_tree().process_frame


func after_each() -> Signal:
    channel_tree.uproot()
    channel_debug.uproot()
    await get_tree().process_frame

    channel_surfer.main_channel = channel_surfer.CHANNEL_PLACEHOLDER
    EditorInterface.save_scene()
    return get_tree().process_frame


func after_all() -> Signal:
    EditorInterface.close_scene()
    return get_tree().process_frame


func test_channel_tree_error() -> bool:
    var tree_item: TreeItem = channel_tree.get_root().get_child(0)
    channel_tree._on_button_clicked(tree_item, 0, 0, MOUSE_BUTTON_LEFT)
    await get_tree().process_frame
    return channel_debug.get_root() and channel_debug.get_root().get_child_count() == 1


func test_channel_tree_fix() -> bool:
    var tree_item: TreeItem = channel_tree.get_root().get_child(0)
    channel_tree._on_button_clicked(tree_item, 0, 0, MOUSE_BUTTON_LEFT)
    await get_tree().process_frame
    channel_tree._add_tree_item(channel_tree.get_root(), 0)
    await get_tree().process_frame
    return not channel_debug.get_root() or channel_debug.get_root().get_child_count() == 0