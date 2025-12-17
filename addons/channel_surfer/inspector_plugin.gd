@tool
extends EditorInspectorPlugin


var ClassPicker = preload("res://addons/channel_surfer/class_picker.gd")
var PostcardPicker = preload("res://addons/channel_surfer/postcard_picker.gd")
var prop_name: String


func _can_handle(object):
    return true


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
    if EditorInterface.get_inspector().get_edited_object() is ChannelSurfer:
        if object.get_class() == "EditorPropertyArray" and hint_string == "ParcelType":
            add_property_editor(prop_name, ClassPicker.new())
            return true
        if object.get_class() == "EditorPropertyArray" and hint_string == "PostcardType":
            add_property_editor(prop_name, PostcardPicker.new())
            return true
        prop_name = name
    return false