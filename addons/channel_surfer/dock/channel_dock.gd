@tool
extends Control


const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const CHANNEL_TREE_TYPE: Resource = preload(CS_PATHS.TREE_TYPE)
const CHANNEL_DEBUG_TYPE: Resource = preload(CS_PATHS.DEBUG_TYPE)
const CS_CONFIG_TYPE: Resource = preload(CS_PATHS.CONFIG_TYPE)

@export var debug_icon: Texture2D
@export var alert_icon: Texture2D
@export var locked_icon: Texture2D
@export var unlocked_icon: Texture2D

@onready var channel_tree: CHANNEL_TREE_TYPE = %ChannelTree
@onready var channel_debug: CHANNEL_DEBUG_TYPE = %ChannelDebug
@onready var channel_settings: VBoxContainer = %ChannelSettings
@onready var channel_button: Button = %ChannelButton
@onready var debug_button: Button = %DebugButton
@onready var lock_button: Button = %LockButton
@onready var settings_button: Button = %SettingsButton
@onready var cs_config: CS_CONFIG_TYPE = preload(CS_PATHS.CONFIG_STORE)


func _ready() -> void:
    channel_debug.hide()
    channel_tree.show()
    lock_button.show()

    channel_debug.alerts_filled.connect(_on_alerts_filled)
    channel_debug.alerts_cleared.connect(_on_alerts_cleared)
    channel_debug.instance_map_changed.connect(_on_instance_map_changed)
    channel_button.pressed.connect(_on_channel_button_pressed)
    debug_button.pressed.connect(_on_debug_button_pressed)
    lock_button.pressed.connect(_on_lock_button_pressed)
    settings_button.pressed.connect(_on_settings_button_pressed)
    channel_tree.channel_map_changed.connect(_on_channel_map_changed)
    channel_tree.channel_edited.connect(_on_channel_edited)

    var instance_map: Dictionary = _load_instance_map()
    channel_debug.set_instance_map(instance_map)

    var channel_map: Dictionary = _load_channel_map()
    channel_tree.build_tree(channel_map)
    channel_debug.update_alerts(channel_map)

    _set_lock_button_icon(channel_tree.is_locked)

    var temp_dir: DirAccess = DirAccess.open("res://")
    if not temp_dir.dir_exists(CS_PATHS.TEMP_STORE):
        temp_dir.make_dir(CS_PATHS.TEMP_STORE)


func _on_channel_edited(current_text: String, prev_text: String, parent_text: String) -> void:
    if cs_config.is_auto_updating:
        channel_debug.dispatch_channel_edits(current_text, prev_text, parent_text)
    else:
        channel_debug.update_alerts(channel_tree.get_channel_map())


func _load_instance_map() -> Dictionary:
    if not FileAccess.file_exists(CS_PATHS.INSTANCE_STORE):
        return {}

    var file: FileAccess = FileAccess.open(CS_PATHS.INSTANCE_STORE, FileAccess.READ)
    var instance_map: Dictionary = JSON.to_native(JSON.parse_string(file.get_as_text()), true)
    file.close()
    return instance_map


func _load_channel_map() -> Dictionary:
    if not FileAccess.file_exists(CS_PATHS.CHANNEL_STORE):
        return {}

    var file: FileAccess = FileAccess.open(CS_PATHS.CHANNEL_STORE, FileAccess.READ)
    var channel_map: Dictionary = JSON.to_native(JSON.parse_string(file.get_as_text()), true)
    file.close()
    return channel_map


func _on_instance_map_changed(new_map: Dictionary) -> void:
    var file: FileAccess = FileAccess.open(CS_PATHS.INSTANCE_STORE, FileAccess.WRITE)
    file.store_string(JSON.stringify(JSON.from_native(new_map, true), "\t"))
    file.close()

    channel_debug.update_alerts(channel_tree.get_channel_map())


func _on_channel_map_changed(channel_map: Dictionary) -> void:
    var file: FileAccess = FileAccess.open(CS_PATHS.CHANNEL_STORE, FileAccess.WRITE)
    file.store_string(JSON.stringify(JSON.from_native(channel_map, true), "\t"))
    file.close()

    channel_debug.update_alerts(channel_map)


func _on_lock_button_pressed() -> void:
    channel_tree.is_locked = not channel_tree.is_locked
    channel_tree.build_tree()

    _set_lock_button_icon(channel_tree.is_locked)


func _set_lock_button_icon(is_locked: bool) -> void:
    if is_locked:
        lock_button.icon = locked_icon
    else:
        lock_button.icon = unlocked_icon


func _on_settings_button_pressed() -> void:
    channel_settings.visible = not channel_settings.visible


func _on_alerts_filled() -> void:
    debug_button.icon = alert_icon


func _on_alerts_cleared() -> void:
    debug_button.icon = debug_icon


func _on_channel_button_pressed() -> void:
    channel_debug.hide()
    channel_tree.show()
    settings_button.show()
    lock_button.show()


func _on_debug_button_pressed() -> void:
    channel_tree.hide()
    settings_button.hide()
    lock_button.hide()
    channel_debug.show()
