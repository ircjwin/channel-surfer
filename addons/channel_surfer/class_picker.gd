extends EditorProperty


const PLACEHOLDER_TEXT: String = "Pick class..."
const PLACEHOLDER_ICON: String = "Object"

var button_text: String = PLACEHOLDER_TEXT
var updating: bool = false
var property_control: Button


func _init() -> void:
    property_control = Button.new()
    property_control.clip_text = true
    add_child(property_control)
    add_focusable(property_control)
    refresh_control_text()
    property_control.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
    if updating:
        return

    EditorInterface.popup_create_dialog(parse_dialog_result, "Object", "", "Class Picker", [])


func _update_property() -> void:
    var new_value: String = get_edited_object()[get_edited_property()]

    if not new_value:
        new_value = PLACEHOLDER_TEXT

    if new_value == button_text:
        return

    updating = true
    button_text = new_value
    refresh_control_text()
    updating = false


func parse_dialog_result(result: StringName) -> void:
    if not result:
        return

    emit_changed(get_edited_property(), result)


func refresh_control_text() -> void:
    property_control.text = button_text
    if button_text == PLACEHOLDER_TEXT:
        property_control.icon = property_control.get_theme_icon(PLACEHOLDER_ICON, &"EditorIcons")
    else:
        if not ClassDB.get_class_list().has(button_text):
            for global_class in ProjectSettings.get_global_class_list():
                if global_class.class == button_text:
                    if global_class.icon:
                        property_control.icon = load(global_class.icon)
                    else:
                        property_control.icon = property_control.get_theme_icon(global_class.base, &"EditorIcons")
        else:
            property_control.icon = property_control.get_theme_icon(button_text, &"EditorIcons")
