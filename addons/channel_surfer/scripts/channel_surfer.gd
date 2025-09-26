@tool
class_name ChannelSurfer
extends Node


const CHANNEL_PREFIX: String = "secure_channel"
const CHANNEL_PLACEHOLDER: String = "none"
const COMPONENT_GROUP: String = "channel_surfer_component"
const DEBUG_GROUP: String = "channel_surfer_debug"
const MAP_GROUP: String = "channel_surfer_map"
const ID_KEY: String = "cs_uid"

var channel_map: Dictionary
var main_channel: String = CHANNEL_PLACEHOLDER: set = _set_main_channel
var sub_channel: String = CHANNEL_PLACEHOLDER: set = _set_sub_channel
var main_channel_group: String = "": set = _set_main_channel_group
var sub_channel_group: String = "": set = _set_sub_channel_group
var _is_recipient: bool = false
var _has_connected = false


func _enter_tree() -> void:
    if not is_in_group(COMPONENT_GROUP):
        add_to_group(COMPONENT_GROUP)
    if not has_meta(ID_KEY):
        set_meta(ID_KEY, CSUID.generate())
    channel_map = {}


func _exit_tree() -> void:
    _has_connected = false


func _notification(what: int) -> void:
    if what == NOTIFICATION_EDITOR_POST_SAVE:
        _sync_channels()


func _process(delta: float) -> void:
    if  not _has_connected:
        _sync_channels()

        if Engine.is_editor_hint():
            _load_channel_map()


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
        _sync_channels()
        return true
    if property == "sub":
        sub_channel = value.to_snake_case()
        _sync_channels()
        return true
    return false


func _get_most_precise() -> String:
    return sub_channel_group if sub_channel_group else main_channel_group


func _set_main_channel(value: String) -> void:
    main_channel = value
    if main_channel == CHANNEL_PLACEHOLDER:
        main_channel_group = ""
    else:
        main_channel_group = CHANNEL_PREFIX + "_" + main_channel
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


func _sync_channels() -> void:
    if is_inside_tree():
        get_tree().call_group(DEBUG_GROUP, "add_instance", self)


func _load_channel_map() -> void:
    if is_inside_tree():
        get_tree().call_group(MAP_GROUP, "dispatch_channel_map")


func start_sync() -> void:
    _has_connected = false


func end_sync() -> void:
    _has_connected = true
