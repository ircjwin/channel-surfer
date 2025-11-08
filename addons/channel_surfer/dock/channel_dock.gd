@tool
extends Control


const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const CHANNEL_TREE_TYPE: Resource = preload(CS_PATHS.TREE_TYPE)
const CHANNEL_DEBUG_TYPE: Resource = preload(CS_PATHS.DEBUG_TYPE)
const CS_CONFIG_TYPE: Resource = preload(CS_PATHS.CONFIG_TYPE)
const DEV_CHANNEL_PREFIX: String = "cs_dev"
const DEBUG_GROUP: String = DEV_CHANNEL_PREFIX + "_debug"

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

var cs_config: CS_CONFIG_TYPE


func _enter_tree() -> void:
    if not is_in_group(DEBUG_GROUP):
        add_to_group(DEBUG_GROUP)


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
    channel_settings.auto_update_check_box.toggled.connect(_on_channel_settings_auto_update_toggled)

    _load_config()
    _set_lock_button_icon()
    channel_tree.is_locked = cs_config.is_channel_locked

    var instance_map: Dictionary = _load_instance_map()
    channel_debug.set_instance_map(instance_map)

    var channel_map: Dictionary = _load_channel_map()
    channel_tree.build_tree(channel_map)
    channel_debug.update_alerts(channel_map)

    var temp_dir: DirAccess = DirAccess.open("res://")
    if not temp_dir.dir_exists(CS_PATHS.TEMP_STORE):
        temp_dir.make_dir(CS_PATHS.TEMP_STORE)


func _on_node_added(node: Node) -> void:
    if node is ChannelSurfer:
        channel_debug.tag_surfer(node)
        channel_tree.set_surfer_channel_map(node)


func _on_scene_saved(filepath: String) -> void:
    channel_debug.resolve_save_conflict(filepath)


func _on_file_removed(file: String) -> void:
    channel_debug.resolve_delete_conflict(file)


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


func _load_config() -> void:
    if not FileAccess.file_exists(CS_PATHS.CONFIG_STORE):
        cs_config = CS_CONFIG_TYPE.new()
        _save_config()
    else:
        var file: FileAccess = FileAccess.open(CS_PATHS.CONFIG_STORE, FileAccess.READ)
        cs_config = JSON.to_native(JSON.parse_string(file.get_as_text()), true)
        file.close()


func _save_config() -> void:
    var file: FileAccess = FileAccess.open(CS_PATHS.CONFIG_STORE, FileAccess.WRITE)
    file.store_string(JSON.stringify(JSON.from_native(cs_config, true), "\t"))
    file.close()


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

    cs_config.is_channel_locked = channel_tree.is_locked
    _save_config()

    _set_lock_button_icon()


func _set_lock_button_icon() -> void:
    if cs_config.is_channel_locked:
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


func _on_channel_settings_auto_update_toggled(toggled_on: bool) -> void:
    cs_config.is_auto_updating = toggled_on
    _save_config()