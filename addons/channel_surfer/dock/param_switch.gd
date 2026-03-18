@tool
extends HBoxContainer


const VARIANT_TYPES = [
    TYPE_BOOL,
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_STRING,
    TYPE_VECTOR2,
    TYPE_VECTOR2I,
    TYPE_RECT2,
    TYPE_RECT2I,
    TYPE_VECTOR3,
    TYPE_VECTOR3I,
    TYPE_TRANSFORM2D,
    TYPE_VECTOR4,
    TYPE_VECTOR4I,
    TYPE_PLANE,
    TYPE_QUATERNION,
    TYPE_AABB,
    TYPE_BASIS,
    TYPE_TRANSFORM3D,
    TYPE_PROJECTION,
    TYPE_COLOR,
    TYPE_STRING_NAME,
    TYPE_NODE_PATH,
    TYPE_RID,
    TYPE_OBJECT,
    TYPE_CALLABLE,
    TYPE_SIGNAL,
    TYPE_DICTIONARY,
    TYPE_ARRAY,
    TYPE_PACKED_BYTE_ARRAY,
    TYPE_PACKED_INT32_ARRAY,
    TYPE_PACKED_INT64_ARRAY,
    TYPE_PACKED_FLOAT32_ARRAY,
    TYPE_PACKED_FLOAT64_ARRAY,
    TYPE_PACKED_STRING_ARRAY,
    TYPE_PACKED_VECTOR2_ARRAY,
    TYPE_PACKED_VECTOR3_ARRAY,
    TYPE_PACKED_COLOR_ARRAY,
    TYPE_PACKED_VECTOR4_ARRAY,
]

@onready var var_text_edit: TextEdit = %VarTextEdit
@onready var hint_check_button: CheckButton = %HintCheckButton
@onready var type_option_button: OptionButton = %TypeOptionButton
@onready var class_button: Button = %ClassButton
@onready var delete_param_button: Button = %DeleteParamButton

var arg_hint: String
var is_base_type: bool = true
var param_name: String
var param_hint: String


func _ready() -> void:
    class_button.hide()

    hint_check_button.toggled.connect(_on_hint_check_button_toggled)
    class_button.pressed.connect(_on_class_button_pressed)
    delete_param_button.pressed.connect(_on_delete_param_button_pressed)
    var_text_edit.text_set.connect(_on_var_text_edit_text_set)


func _on_var_text_edit_text_set() -> void:
    param_name = var_text_edit.text


func _on_hint_check_button_toggled(toggled_on: bool) -> void:
    if toggled_on:
        type_option_button.hide()
        class_button.show()
    else:
        class_button.hide()
        type_option_button.show()


func _on_class_button_pressed() -> void:
    EditorInterface.popup_create_dialog(parse_dialog_result, "Object", "", "Class Picker", [])


func _on_delete_param_button_pressed() -> void:
    queue_free()


func build_switch() -> void:
    delete_param_button.icon = get_theme_icon("Remove", &"EditorIcons")
    type_option_button.add_item("Type...")
    for base_type: int in VARIANT_TYPES:
        var type_as_string: String = type_string(base_type)
        var type_icon: Texture2D = type_option_button.get_theme_icon(type_as_string, &"EditorIcons")
        type_option_button.add_icon_item(type_icon, type_as_string)


func parse_dialog_result(result: StringName) -> void:
    if not result:
        return

    arg_hint = result