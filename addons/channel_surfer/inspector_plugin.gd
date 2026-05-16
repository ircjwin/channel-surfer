@tool
extends EditorInspectorPlugin


var SwitchLabel = preload("res://addons/channel_surfer/dock/switch_label.gd")
var SwitchButton = preload("res://addons/channel_surfer/dock/switch_button.gd")


func _can_handle(object):
    return true


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
    if object is ChannelSurfer:
        if hint_string == "SwitchMethodType":
            var contra = Label.new()
            var index = name.get_slice_count("/") - 1
            contra.text = name.get_slice("/", index)
            add_property_editor(name, contra)
            return true
        if hint_string == "SwitchParamType":
            var contra = HBoxContainer.new()
            var label_1 = Label.new()
            var label_2 = Label.new()
            label_1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            label_2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            label_1.clip_text = true
            label_2.clip_text = true
            label_1.size_flags_stretch_ratio = 3.0
            label_2.size_flags_stretch_ratio = 2.0
            contra.add_child(label_1)
            contra.add_child(label_2)
            var index = name.get_slice_count("/") - 1
            var switch_name = name.get_slice("/", index).get_slice(":", 0)
            label_1.text = switch_name
            label_2.text = name.get_slice("/", index).get_slice(":", 1)
            add_custom_control(contra)
            return true
        if hint_string == "SwitchCopyType":
            var switch_button = SwitchButton.new()
            var channel_name = name.get_slice("/", 0)
            var switch_name = name.get_slice("/", 1)
            switch_button.set_copy_text(object.name.to_snake_case() + "." + channel_name + "." + switch_name + "()")
            add_custom_control(switch_button)
            return true
    return false
