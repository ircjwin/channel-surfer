@tool
extends TestBase


const TEST_PATHS: Resource = preload("res://tests/core/test_paths.gd")


func before_all() -> Signal:
    # EditorInterface.open_scene_from_path(TEST_PATHS.TEST_SCENE_PATH)
    ## Just set the main/sub directly; don't need official channels
    # channel_tree._add_tree_item(channel_tree.get_root(), 0)
    return get_tree().process_frame


func before_each() -> Signal:
    return get_tree().process_frame


func after_each() -> Signal:
    # channel_debug.uproot()
    return get_tree().process_frame


func after_all() -> Signal:
    # EditorInterface.close_scene()
    return get_tree().process_frame


func test_channel_surfer_save_inside_tree() -> bool:
    return false


func test_channel_surfer_save_outside_tree() -> bool:
    # var temp_root: Node = Node.new()
    # temp_root.name = "TempRoot"
    # var temp_packed_scene: PackedScene = PackedScene.new()
    # temp_packed_scene.pack(temp_root)
    # ResourceSaver.save(temp_packed_scene, "res://tests/core/temp_scene.tscn")
    # await get_tree().process_frame

    # var temp_dir: DirAccess = DirAccess.open("res://")
    # temp_dir.remove("res://tests/core/temp_scene.tscn")
    # await get_tree().process_frame

    return false


func test_channel_surfer_fix() -> bool:
    return false