@tool
class_name ChannelSurfer
extends Node


@export var main_channel: SecureChannels.Main = SecureChannels.Main.NONE: set = _set_main_channel
var sub_channel: int = 0: set = _set_sub_channel

const CHANNEL_PREFIX: String = "secure_channel"
const MAIN_PREFIX: String = "_main:"
const SUB_PREFIX: String = "_sub:"

var main_channel_group: String = "": set = _set_main_channel_group
var sub_channel_group: String = "": set = _set_sub_channel_group
var _is_recipient: bool = false: set = _set_is_recipient

var channel_map: Dictionary

func _init() -> void:
    _load_channel_map()

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    var sub_channel_name: String = str(SecureChannels.Main.keys()[main_channel]).capitalize()

    if channel_map.has(sub_channel_name):
        var sub_channel_hint_string: String = str(SecureChannels[sub_channel_name]) \
                                              .trim_prefix("{") \
                                              .trim_suffix("}") \
                                              .replace("\"", "") \
                                              .capitalize()
        properties.append({
            "name": &"sub_channel",
            "type": TYPE_INT,
            "usage": PROPERTY_USAGE_DEFAULT,
            "hint": PROPERTY_HINT_ENUM,
            "hint_string": sub_channel_hint_string
        })

    return properties

func _get_most_precise() -> String:
    return sub_channel_group if sub_channel_group else main_channel_group

func _get_main_name() -> String:
    var main_name: String = SecureChannels.Main.find_key(main_channel)
    return "_" + main_name.to_lower()

func _get_sub_name() -> String:
    var main_name: String = str(SecureChannels.Main.find_key(main_channel)).capitalize()
    if channel_map.has(main_name):
        var sub_map: Dictionary = channel_map[main_name]
        var sub_name: String = sub_map.find_key(sub_channel)
        return "_" + sub_name.to_lower()
    return ""

func _set_is_recipient(value: bool) -> void:
    _is_recipient = value
    if not _is_recipient:
        _update_channel_group(main_channel_group, "")
        _update_channel_group(sub_channel_group, "")

func _set_main_channel(value: SecureChannels.Main) -> void:
    main_channel = value
    if main_channel == 0:
        main_channel_group = ""
    else:
        main_channel_group = CHANNEL_PREFIX + _get_main_name()
    sub_channel = 0
    notify_property_list_changed()

func _set_sub_channel(value: int) -> void:
    sub_channel = value
    if sub_channel == 0:
        sub_channel_group = ""
    else:
        sub_channel_group = main_channel_group + _get_sub_name()

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
        add_to_group(new_channel, true)

func _load_channel_map() -> void:
    var secure_channels_script: Script = SecureChannels.new().get_script()
    channel_map = secure_channels_script.get_script_constant_map()

func _receive(value: bool) -> void:
    _is_recipient = value

