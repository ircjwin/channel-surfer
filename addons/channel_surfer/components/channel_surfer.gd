@tool
@icon("res://addons/channel_surfer/assets/surfer_icon.png")
class_name ChannelSurfer
extends Node


@export_storage var switch_scripts: Array = []

const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const USER_CHANNEL_PREFIX: String = "cs_user"
const CHANNEL_PLACEHOLDER: String = "none"

# TODO: temporary while debug is offline
const DEV_CHANNEL_PREFIX: String = "cs_dev"
const COMPONENT_GROUP: String = DEV_CHANNEL_PREFIX + "_component"

var channel_map: Dictionary
var _is_recipient: bool = false
var _is_synced = false

var switch_names: Array = []:
    set(val):
        switch_names = val
        switch_scripts.clear()
        var temp_dir: DirAccess = DirAccess.open(CS_PATHS.SWITCH_DIR)
        for file_name: String in temp_dir.get_files():
            if file_name.ends_with(".gd") and switch_names.has(file_name.replace(".gd", "")):
                var switch_script: Script = ResourceLoader.load(CS_PATHS.SWITCH_DIR + file_name)
                switch_scripts.append(switch_script)
        notify_property_list_changed()


func _enter_tree() -> void:
    channel_map = {}
    # TODO: temporary while debug is offline
    add_to_group(COMPONENT_GROUP)


func _exit_tree() -> void:
    # TODO: temporary while debug is offline
    remove_from_group(COMPONENT_GROUP)


# func _notification(what: int) -> void:
#     if not is_inside_tree() and what == NOTIFICATION_EDITOR_PRE_SAVE:
#         _create_save_state()


func report_in(report_func: Callable = func(): pass) -> void:
    report_func.call(self)


func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []

    # TODO: cleanup name retrieval
    for switch_script: Script in switch_scripts:
        var switch_name: String = switch_script.get_script_property_list()[0]["name"].replace(".gd", "")
        for switch_method: Dictionary in switch_script.get_script_method_list():
            properties.append({
                "name": switch_name + "/" + switch_method["name"] + "/" + "chungus",
                "type": TYPE_CALLABLE,
                "usage": PROPERTY_USAGE_EDITOR,
                "hint": PROPERTY_HINT_TOOL_BUTTON,
                # "hint_string": ",ActionCopy",
                "hint_string": "SwitchCopyType",
            })
            # if switch_method["args"].is_empty():
            #     properties.append({
            #         "name": switch_name + "/" + switch_method["name"],
            #         "type": TYPE_STRING,
            #         "usage": PROPERTY_USAGE_DEFAULT,
            #         "hint": PROPERTY_HINT_TYPE_STRING,
            #         "hint_string": "SwitchMethodType",
            #     })
            # else:
            if not switch_method["args"].is_empty():
                for switch_arg: Dictionary in switch_method["args"]:
                    var switch_type: String
                    if switch_arg["class_name"].is_empty():
                        if switch_arg["type"] == TYPE_NIL:
                            switch_type = "Variant"
                        else:
                            switch_type = type_string(switch_arg["type"])
                    else:
                        switch_type = switch_arg["class_name"]
                    properties.append({
                        "name": switch_name + "/" + switch_method["name"] + "/" + switch_arg["name"] + ":" + switch_type,
                        "type": TYPE_STRING,
                        "usage": PROPERTY_USAGE_DEFAULT,
                        "hint": PROPERTY_HINT_TYPE_STRING,
                        "hint_string": "SwitchParamType",
                    })

    var main_hint_string: String = CHANNEL_PLACEHOLDER.capitalize() + ","
    var main_channel_list: Array = channel_map.keys()
    var make_readable: Callable = func(x: String): return x.capitalize()

    main_hint_string += ",".join(main_channel_list.map(make_readable))

    properties.append({
        "name": "switches",
        "type": TYPE_ARRAY,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_TYPE_STRING,
        "hint_string": "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_ENUM, main_hint_string]
    })

    return properties


func _get(property: StringName) -> Variant:
    if property == "switches":
        return switch_names.map(func(x): return x.capitalize())
    if property.ends_with("chungus"):
        var brawler: Callable = func(): print("CHUNGUS")
        return brawler
    return null


func _set(property: StringName, value: Variant) -> bool:
    if property == "switches":
        value = value.map(func(x): return CHANNEL_PLACEHOLDER if x == null else x)
        switch_names = value.map(func(x): return x.to_snake_case())
        return true
    return false


# func _create_save_state() -> void:
#     var packed_surfer: PackedScene = PackedScene.new()
#     var packed_filename: String = "%s-%s.tscn" % [get_parent().name, name]
#     packed_surfer.pack(self)
#     ResourceSaver.save(packed_surfer, CS_PATHS.TEMP_DIR + packed_filename)


# func _set_main_channel(value: String) -> void:
#     main_channel = value
#     if main_channel == CHANNEL_PLACEHOLDER:
#         main_channel_group = ""
#     else:
#         main_channel_group = USER_CHANNEL_PREFIX + "_" + main_channel
#     notify_property_list_changed()


# func _set_main_channel_group(value: String) -> void:
#     if _is_recipient:
#         _update_channel_group(main_channel_group, value)
#     main_channel_group = value


func _update_channel_group(old_channel: String, new_channel: String) -> void:
    if old_channel:
        remove_from_group(old_channel)
    if new_channel and not is_in_group(new_channel):
        add_to_group(new_channel)


func _receive(value: bool) -> void:
    _is_recipient = value

    # if value:
    #     _update_channel_group("", main_channel_group)
    # else:
    #     _update_channel_group(main_channel_group, "")


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
