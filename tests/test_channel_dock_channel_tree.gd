@tool
extends TestBase


func before_all() -> Signal:
    return get_tree().process_frame


func before_each() -> Signal:
    return get_tree().process_frame


func after_each() -> Signal:
    return get_tree().process_frame


func after_all() -> Signal:
    return get_tree().process_frame