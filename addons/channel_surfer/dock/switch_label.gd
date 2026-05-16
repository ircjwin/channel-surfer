extends EditorProperty


var property_control: Label


func _init() -> void:
    property_control = Label.new()
    property_control.clip_text = true
    add_child(property_control)


func set_switch_type(type_name: String) -> void:
    property_control.text = type_name
