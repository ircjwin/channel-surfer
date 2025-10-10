@tool
class_name DebugLog
extends Control


@export var collapse_icon: Texture2D
@export var expand_icon: Texture2D

@onready var collapse_button: Button = %CollapseButton
@onready var scene_path_label: Label = %ScenePathLabel
@onready var scene_nav_button: Button = %SceneNavButton
@onready var instance_errors: VBoxContainer = %InstanceErrors

var scene_path: String:
	set(val):
		scene_path = val
		scene_path_label.text = val


func _ready() -> void:
	collapse_button.toggle_mode = true

	collapse_button.toggled.connect(_on_collapse_button_toggled)
	scene_nav_button.pressed.connect(_on_scene_nav_button_pressed)


func display(debug_header: String, is_expanded: bool = false) -> void:
	scene_path = debug_header
	_on_collapse_button_toggled(is_expanded)


func add_error(error_text: String) -> void:
	var error_label: RichTextLabel = RichTextLabel.new()
	error_label.bbcode_enabled = true
	error_label.fit_content = true
	error_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	error_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	instance_errors.add_child(error_label)
	error_label.append_text(error_text)


func _on_collapse_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		collapse_button.icon = expand_icon
		instance_errors.show()
	else:
		collapse_button.icon = collapse_icon
		instance_errors.hide()


func _on_scene_nav_button_pressed() -> void:
	EditorInterface.open_scene_from_path(scene_path)
