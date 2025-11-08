extends Node


const TESTS_PATH: String = "res://tests/"

var total_passed: int = 0
var total_failed: int = 0


func _ready() -> void:
    await _run_tests()
    queue_free()


func _run_tests() -> void:
    var test_dir: DirAccess = DirAccess.open(TESTS_PATH)
    for filename: String in test_dir.get_files():
        if filename.begins_with("test_") and filename.ends_with(".gd"):
            var test_node: TestBase = load(TESTS_PATH + filename).new()
            get_parent().add_child(test_node)
            test_node.run_tests()
            await test_node.tests_finished
            total_passed += test_node.passed
            total_failed += test_node.failed
            test_node.queue_free()
    _summarize()


func _summarize() -> void:
    print_rich("\n\t[color=lime]PASSED %s[/color]\n\t[color=coral]FAILED %s[/color]" % [total_passed, total_failed])