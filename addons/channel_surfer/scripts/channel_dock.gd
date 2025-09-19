@tool
extends Control


@export var debug_icon: Texture2D
@export var alert_icon: Texture2D
@export var locked_icon: Texture2D
@export var unlocked_icon: Texture2D

@onready var channel_tree: ChannelTree = %ChannelTree
@onready var channel_debug: ChannelDebug = %ChannelDebug
@onready var channel_button: Button = %ChannelButton
@onready var debug_button: Button = %DebugButton
@onready var lock_button: Button = %LockButton

const CHANNEL_MAP_PATH: String = "res://addons/channel_surfer/data/channel_map.json"
const INSTANCE_MAP_PATH: String = "res://addons/channel_surfer/data/instance_map.json"

## Consider checks for button click

func _ready() -> void:
    add_to_group(ChannelSurfer.MAP_GROUP)

    channel_debug.hide()
    channel_tree.show()
    lock_button.show()

    channel_debug.alerts_filled.connect(_on_alerts_filled)
    channel_debug.alerts_cleared.connect(_on_alerts_cleared)
    channel_debug.instance_map_changed.connect(_on_instance_map_changed)
    channel_button.pressed.connect(_on_channel_button_pressed)
    debug_button.pressed.connect(_on_debug_button_pressed)
    lock_button.pressed.connect(_on_lock_button_pressed)
    channel_tree.channel_map_changed.connect(_on_channel_map_changed)

    var instance_map: Dictionary = _load_instance_map()
    channel_debug.set_instance_map(instance_map)

    var channel_map: Dictionary = _load_channel_map()
    channel_tree.build_tree(channel_map)
    channel_debug.update_alerts(channel_map)


func _load_instance_map() -> Dictionary:
    if not FileAccess.file_exists(INSTANCE_MAP_PATH):
        return {}

    var file: FileAccess = FileAccess.open(INSTANCE_MAP_PATH, FileAccess.READ)
    var instance_map: Dictionary = JSON.parse_string(file.get_as_text())
    file.close()
    return instance_map


func _load_channel_map() -> Dictionary:
    if not FileAccess.file_exists(CHANNEL_MAP_PATH):
        return {}

    var file: FileAccess = FileAccess.open(CHANNEL_MAP_PATH, FileAccess.READ)
    var channel_map: Dictionary = JSON.parse_string(file.get_as_text())
    file.close()
    return channel_map


func _on_instance_map_changed(new_map: Dictionary) -> void:
    var file: FileAccess = FileAccess.open(INSTANCE_MAP_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(new_map))
    file.close()

    channel_debug.update_alerts(channel_tree.get_channel_map())


func _on_channel_map_changed(channel_map: Dictionary) -> void:
    var file: FileAccess = FileAccess.open(CHANNEL_MAP_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(channel_map))
    file.close()

    channel_debug.update_alerts(channel_map)
    _dispatch_channel_map(channel_map)


func request_channel_map() -> void:
    _dispatch_channel_map(channel_tree.get_channel_map())


func _dispatch_channel_map(requested_map: Dictionary) -> void:
    get_tree().call_group(ChannelSurfer.COMPONENT_GROUP, "set_channel_map", requested_map)
    get_tree().call_group.call_deferred(ChannelSurfer.COMPONENT_GROUP, "notify_property_list_changed")


func _on_lock_button_pressed() -> void:
    channel_tree.is_locked = not channel_tree.is_locked
    channel_tree.build_tree()
    if channel_tree.is_locked:
        lock_button.icon = locked_icon
    else:
        lock_button.icon = unlocked_icon


func _on_alerts_filled() -> void:
    debug_button.icon = alert_icon


func _on_alerts_cleared() -> void:
    debug_button.icon = debug_icon


func _on_channel_button_pressed() -> void:
    channel_debug.hide()
    channel_tree.show()
    lock_button.show()


func _on_debug_button_pressed() -> void:
    channel_tree.hide()
    lock_button.hide()
    channel_debug.show()
