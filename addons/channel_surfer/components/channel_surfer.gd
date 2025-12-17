@tool
@icon("res://addons/channel_surfer/assets/surfer_icon.png")
class_name ChannelSurfer
extends Node


const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")

const USER_CHANNEL_PREFIX: String = "cs_user"
const CHANNEL_PLACEHOLDER: String = "none"

var channel_map: Dictionary
var main_channel: String = CHANNEL_PLACEHOLDER: set = _set_main_channel
var sub_channel: String = CHANNEL_PLACEHOLDER: set = _set_sub_channel
var main_channel_group: String = "": set = _set_main_channel_group
var sub_channel_group: String = "": set = _set_sub_channel_group
var _is_recipient: bool = false
var _is_synced = false


func _enter_tree() -> void:
    channel_map = {}


func _notification(what: int) -> void:
    if not is_inside_tree() and what == NOTIFICATION_EDITOR_PRE_SAVE:
        _create_save_state()


func report_in(report_func: Callable = func(): pass) -> void:
    report_func.call(self)


func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    var main_hint_string: String = CHANNEL_PLACEHOLDER.capitalize() + ","
    var sub_hint_string: String = CHANNEL_PLACEHOLDER.capitalize() + ","

    var main_channel_list: Array = channel_map.keys()
    var sub_channel_list: Array = []
    if channel_map.has(main_channel):
        sub_channel_list = channel_map[main_channel]

    var make_readable: Callable = func(x: String): return x.capitalize()
    main_hint_string += ",".join(main_channel_list.map(make_readable))
    sub_hint_string += ",".join(sub_channel_list.map(make_readable))

    properties.append({
        "name": "main",
        "type": TYPE_STRING,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_ENUM,
        "hint_string": main_hint_string
    })
    properties.append({
        "name": "sub",
        "type": TYPE_STRING,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_ENUM,
        "hint_string": sub_hint_string
    })
    return properties


func _get(property: StringName) -> Variant:
    if property == "main":
        return main_channel.capitalize()
    if property == "sub":
        return sub_channel.capitalize()
    return null


func _set(property: StringName, value: Variant) -> bool:
    if property == "main":
        main_channel = value.to_snake_case()
        sub_channel = CHANNEL_PLACEHOLDER
    elif property == "sub":
        sub_channel = value.to_snake_case()
    else:
        return false
    return true


func _create_save_state() -> void:
    var packed_surfer: PackedScene = PackedScene.new()
    var packed_filename: String = "%s-%s.tscn" % [get_parent().name, name]
    packed_surfer.pack(self)
    ResourceSaver.save(packed_surfer, CS_PATHS.TEMP_STORE + packed_filename)


func _get_most_precise() -> String:
    return sub_channel_group if sub_channel_group else main_channel_group


func _set_main_channel(value: String) -> void:
    main_channel = value
    if main_channel == CHANNEL_PLACEHOLDER:
        main_channel_group = ""
    else:
        main_channel_group = USER_CHANNEL_PREFIX + "_" + main_channel
    notify_property_list_changed()


func _set_sub_channel(value: String) -> void:
    sub_channel = value
    if sub_channel == CHANNEL_PLACEHOLDER:
        sub_channel_group = ""
    else:
        sub_channel_group = main_channel_group + "_" + sub_channel


func _set_main_channel_group(value: String) -> void:
    if _is_recipient:
        _update_channel_group(main_channel_group, value)
    main_channel_group = value


func _set_sub_channel_group(value: String) -> void:
    if _is_recipient:
        _update_channel_group(sub_channel_group, value)
    sub_channel_group = value


func _update_channel_group(old_channel: String, new_channel: String) -> void:
    if old_channel:
        remove_from_group(old_channel)
    if new_channel and not is_in_group(new_channel):
        add_to_group(new_channel)


func _receive(value: bool) -> void:
    _is_recipient = value

    if value:
        _update_channel_group("", main_channel_group)
        _update_channel_group("", sub_channel_group)
    else:
        _update_channel_group(main_channel_group, "")
        _update_channel_group(sub_channel_group, "")


func set_channel_map(new_map: Dictionary) -> void:
    channel_map = new_map
    notify_property_list_changed()


# https://forum.godotengine.org/t/how-to-compare-class-name-with-string/116692/3
func get_type_as_string(value: Variant) -> String:
    if value == null:
        return ""

    if value is Object:
        var script: Script = value.get_script()
        if script == null:
            return value.get_class()

        var type_as_string: String = script.get_global_name()
        if type_as_string == "":
            type_as_string = script.get_instance_base_type()

        return type_as_string

    return type_string(typeof(value))


func _send_ping() -> void:
    pass


func _receive_ping() -> void:
    pass


func _send_variant(variant: Variant) -> void:
    pass


func _receive_variant(variant: Variant) -> void:
    pass


func _send_object(object: Object) -> void:
    pass


func _receive_objecdt(object: Object) -> void:
    pass


func _send_request(request: String) -> void:
    pass


func _receive_request(request: String) -> void:
    pass


func _fulfill_request(fulfillment: Variant) -> void:
    pass

