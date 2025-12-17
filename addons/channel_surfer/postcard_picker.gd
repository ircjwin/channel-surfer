extends EditorProperty


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

var property_control: OptionButton


func _init() -> void:
    property_control = OptionButton.new()
    add_child(property_control)
    add_focusable(property_control)


func _update_property() -> void:
    if property_control.item_count == 0:
        var default_icon: Texture2D = property_control.get_theme_icon("Variant", &"EditorIcons")
        property_control.add_icon_item(default_icon, "Pick type...")
        for v_type: int in VARIANT_TYPES:
            var type_as_string: String = type_string(v_type)
            var type_icon: Texture2D = property_control.get_theme_icon(type_as_string, &"EditorIcons")
            property_control.add_icon_item(type_icon, type_as_string)
        return
    var current_value: String = property_control.get_item_text(property_control.get_selected_id())
    emit_changed(get_edited_property(), current_value)
