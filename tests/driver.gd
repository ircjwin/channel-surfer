@tool
extends EditorScript


const TEST_PATHS: Resource = preload("res://tests/core/test_paths.gd")
const TEST_RUNNER_TYPE: Resource = preload("res://tests/runner.gd")
const DEV_CHANNEL_PREFIX: String = "cs_dev"
const DEBUG_GROUP: String = DEV_CHANNEL_PREFIX + "_debug"


func _run():
	EditorInterface.open_scene_from_path(TEST_PATHS.TEST_SCENE_PATH)
	var plugin_node: Node = EditorInterface.get_edited_scene_root().get_tree().get_first_node_in_group(DEBUG_GROUP)
	EditorInterface.close_scene()
	if plugin_node:
		var test_runner: TEST_RUNNER_TYPE = TEST_RUNNER_TYPE.new()
		plugin_node.add_child(test_runner)