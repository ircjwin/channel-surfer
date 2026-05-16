@tool
extends MarginContainer


var copy_button: Button
var copy_text: String = ""


func _ready() -> void:
    var margin_value = 2
    add_theme_constant_override("margin_top", margin_value)
    add_theme_constant_override("margin_left", margin_value)
    add_theme_constant_override("margin_bottom", margin_value)
    add_theme_constant_override("margin_right", margin_value)

    copy_button = Button.new()
    copy_button.size_flags_horizontal = Control.SIZE_FILL
    copy_button.icon = get_theme_icon("ActionCopy", &"EditorIcons")
    copy_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(copy_button)

    copy_button.pressed.connect(_on_copy_button_pressed)


func set_copy_text(new_text: String) -> void:
    copy_text = new_text


func _add_to_clipboard() -> void:
    DisplayServer.clipboard_set(copy_text)
    EditorInterface.get_editor_toaster().push_toast("Switch copied to clipboard")


func _on_copy_button_pressed() -> void:
    _add_to_clipboard()
