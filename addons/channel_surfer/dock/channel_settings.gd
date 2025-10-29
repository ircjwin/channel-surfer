@tool
extends VBoxContainer


@onready var auto_update_check_box: CheckBox = %AutoUpdateCheckBox


func set_auto_update_check_box(toggled_on: bool) -> void:
    auto_update_check_box.button_pressed = toggled_on