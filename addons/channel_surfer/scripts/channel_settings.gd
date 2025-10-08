@tool
extends VBoxContainer


@onready var auto_update_check_box: CheckBox = %AutoUpdateCheckBox
@onready var cs_config: CSConfig = preload("res://addons/channel_surfer/data/cs_config.tres")


func _ready() -> void:
    auto_update_check_box.button_pressed = cs_config.is_auto_updating
    auto_update_check_box.toggled.connect(_on_auto_update_check_box_toggled)


func _on_auto_update_check_box_toggled(toggled_on: bool) -> void:
    cs_config.is_auto_updating = toggled_on
    ResourceSaver.save(cs_config)
