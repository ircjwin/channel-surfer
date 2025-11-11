@abstract
class_name TestBase extends Node


signal tests_finished

const TEST_PATHS: Resource = preload("res://tests/core/test_paths.gd")
const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const CHANNEL_TREE_TYPE: Resource = preload(CS_PATHS.TREE_TYPE)
const CHANNEL_DEBUG_TYPE: Resource = preload(CS_PATHS.DEBUG_TYPE)
const CHANNEL_SETTINGS_TYPE: Resource = preload(CS_PATHS.SETTINGS_TYPE)

@onready var channel_tree: CHANNEL_TREE_TYPE = get_node("../%ChannelTree")
@onready var channel_debug: CHANNEL_DEBUG_TYPE = get_node("../%ChannelDebug")
@onready var channel_settings: CHANNEL_SETTINGS_TYPE = get_node("../%ChannelSettings")

var category: String = ""
var passed: int = 0
var failed: int = 0


@abstract
func before_all() -> Signal


@abstract
func before_each() -> Signal


@abstract
func after_each() -> Signal


@abstract
func after_all() -> Signal


func run_tests() -> void:
    _classify()
    await before_all()
    for test_method: Dictionary in get_method_list():
        if test_method["name"].begins_with("test_"):
            await before_each()
            var result: bool = await call(test_method["name"])
            _grade(test_method["name"], result)
            await after_each()
    await after_all()

    tests_finished.emit()


func _classify() -> void:
    if category:
        print(category)
    else:
        var filepath: String = get_script().resource_path
        var filename: String = filepath.split("/")[-1]
        var formatted_name: String = filename.replace("test_", "").replace(".gd", "").capitalize()
        print(formatted_name)


func _grade(test_name: String, test_result: bool) -> void:
    var formatted_name: String = test_name.replace("test_", "").capitalize()
    var result_color: String = "lime" if test_result else "coral"
    var final_grade: String = "PASSED" if test_result else "FAILED"

    if test_result:
        passed += 1
    else:
        failed += 1

    print_rich("[color=%s]\t◉ %s - %s[/color]" % [result_color, formatted_name, final_grade])


func _checkout(filepath: String) -> String:
    var temp_dir: DirAccess = DirAccess.open("res://")
    var temp_file_id: String = str(randi_range(100000, 999999))
    var temp_filepath: String = filepath.insert(len(filepath) - 5, temp_file_id)
    temp_dir.copy(filepath, temp_filepath)
    return temp_filepath