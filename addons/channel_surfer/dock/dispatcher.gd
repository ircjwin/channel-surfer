@tool
extends Node


const DEV_CHANNEL_PREFIX: String = "cs_dev"
const COMPONENT_GROUP: String = DEV_CHANNEL_PREFIX + "_component"


func dispatch_channel_map(channel_map: Dictionary) -> void:
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE,
        COMPONENT_GROUP, "set_channel_map", channel_map)