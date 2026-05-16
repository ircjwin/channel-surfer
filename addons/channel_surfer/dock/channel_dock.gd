@tool
extends Control


const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const CHANNEL_TREE_TYPE: Resource = preload(CS_PATHS.TREE_TYPE)
const CHANNEL_DEBUG_TYPE: Resource = preload(CS_PATHS.DEBUG_TYPE)
const SWITCHBOARD_TYPE: Resource = preload(CS_PATHS.SWITCHBOARD_TYPE)
const SWITCH_TREE_TYPE: Resource = preload(CS_PATHS.SWITCH_TREE_TYPE)
const CS_CONFIG_TYPE: Resource = preload(CS_PATHS.CONFIG_TYPE)
const DISPATCHER_TYPE: Resource = preload(CS_PATHS.DISPATCHER_TYPE)
const SCRIPT_WRITER_TYPE: Resource = preload(CS_PATHS.SCRIPT_WRITER_TYPE)
const DEV_CHANNEL_PREFIX: String = "cs_dev"
const DEBUG_GROUP: String = DEV_CHANNEL_PREFIX + "_debug"

@onready var channel_tree: CHANNEL_TREE_TYPE = %ChannelTree
@onready var channel_debug: CHANNEL_DEBUG_TYPE = %ChannelDebug
@onready var channel_settings: VBoxContainer = %ChannelSettings
@onready var channel_button: Button = %ChannelButton
@onready var debug_button: Button = %DebugButton
@onready var lock_button: Button = %LockButton
@onready var settings_button: Button = %SettingsButton
@onready var save_button: Button = %SaveButton
@onready var channel_tab: HBoxContainer = %ChannelTab
@onready var switchboard: SWITCHBOARD_TYPE = %Switchboard
@onready var switch_tree: SWITCH_TREE_TYPE = %SwitchTree
@onready var add_channel_button: Button = %AddChannelButton

@onready var dispatcher: DISPATCHER_TYPE = %Dispatcher
@onready var script_writer: SCRIPT_WRITER_TYPE = %ScriptWriter

@onready var locked_icon = get_theme_icon("Lock", &"EditorIcons")
@onready var unlocked_icon = get_theme_icon("Unlock", &"EditorIcons")
@onready var debug_icon = get_theme_icon("Debug", &"EditorIcons")
@onready var alert_icon = get_theme_icon("StatusWarning", &"EditorIcons")
@onready var add_icon = get_theme_icon("Add", &"EditorIcons")

var cs_config: CS_CONFIG_TYPE
var is_modified: bool = false


func _enter_tree() -> void:
    if not is_in_group(DEBUG_GROUP):
        add_to_group(DEBUG_GROUP)


func _ready() -> void:
    save_button.icon = get_theme_icon("Save", &"EditorIcons")
    add_channel_button.icon = add_icon
    channel_debug.hide()
    channel_tab.show()
    lock_button.show()

    # channel_debug.alerts_filled.connect(_on_alerts_filled)
    # channel_debug.alerts_cleared.connect(_on_alerts_cleared)
    # channel_debug.instance_map_changed.connect(_on_instance_map_changed)
    channel_button.pressed.connect(_on_channel_button_pressed)
    debug_button.pressed.connect(_on_debug_button_pressed)
    lock_button.pressed.connect(_on_lock_button_pressed)
    settings_button.pressed.connect(_on_settings_button_pressed)
    channel_tree.channel_map_changed.connect(_on_channel_map_changed)
    channel_tree.channel_edited.connect(_on_channel_edited)
    channel_settings.auto_update_check_box.toggled.connect(_on_channel_settings_auto_update_toggled)
    save_button.pressed.connect(_on_save_button_pressed)
    channel_tree.channel_rmb_selected.connect(_on_channel_tree_channel_rmb_selected)
    switchboard.switchboard_selected.connect(_on_switchboard_switchboard_selected)

    # TODO: attach node_added to dispatcher
    get_tree().node_added.connect(_on_node_added)

    _load_config()
    _set_lock_button_icon()
    channel_tree.is_locked = cs_config.is_channel_locked

    # var instance_map: Dictionary = _load_instance_map()
    # channel_debug.set_instance_map(instance_map)

    var channel_map: Dictionary = _load_channel_map()
    channel_tree.build_tree(channel_map)
    # channel_debug.update_alerts(channel_map)

    var temp_dir: DirAccess = DirAccess.open("res://")
    if not temp_dir.dir_exists(CS_PATHS.TEMP_DIR):
        temp_dir.make_dir(CS_PATHS.TEMP_DIR)

    switchboard.fill_options(channel_map)
    # var switch_map: Dictionary = _load_switch_map()
    # switchboard.fill_switches(switch_map)

    switch_tree.switchboard_changed.connect(_on_switch_tree_switchboard_changed)


# var ticker: float = 0.0
# func _process(delta: float) -> void:
#     ticker += delta
#     if ticker >= 5.0:
#         var gui_control = get_viewport().gui_get_hovered_control()
#         print(gui_control.get_parent())
#         print(gui_control)
#         print(gui_control.get_children(true))
#         var poppy = gui_control.find_child("*PopupPanel*", true, false)
#         if poppy:
#             print(poppy.get_children(true))
#         print("")
#         ticker = 0.0


func _on_switch_tree_switchboard_changed(new_board: Dictionary) -> void:
    var board_index: int = switchboard.main_option_button.selected
    var board_name: String = switchboard.main_option_button.get_item_text(board_index).to_snake_case()
    var channel_map: Dictionary = channel_tree.get_channel_map()
    channel_map.set(board_name, new_board)
    _on_channel_map_changed(channel_map)
    channel_tree.build_tree(channel_map)


func _on_switchboard_switchboard_selected(name: String) -> void:
    switchboard.fill_board(channel_tree.get_channel_map()[name])


func _on_channel_tree_channel_rmb_selected(name: String) -> void:
    switchboard.fill_board(channel_tree.get_channel_map()[name])


func _on_save_button_pressed() -> void:
    # Save channel map
    # Save modified switches
    _on_channel_map_changed(channel_tree.get_channel_map())


func _load_switch_map() -> Dictionary:
    if not FileAccess.file_exists(CS_PATHS.SWITCH_STORE):
        return {}

    var file: FileAccess = FileAccess.open(CS_PATHS.SWITCH_STORE, FileAccess.READ)
    var switch_map: Dictionary = JSON.to_native(JSON.parse_string(file.get_as_text()), true)
    file.close()
    return switch_map


func _on_node_added(node: Node) -> void:
    if node is ChannelSurfer:
        # channel_debug.tag_surfer(node)
        # channel_tree.set_surfer_channel_map(node)
        (node as ChannelSurfer).set_channel_map(channel_tree.get_channel_map())


# func _on_scene_saved(filepath: String) -> void:
#     channel_debug.resolve_save_conflict(filepath)


# func _on_file_removed(file: String) -> void:
#     channel_debug.resolve_delete_conflict(file)


func _on_channel_edited(current_text: String, prev_text: String, parent_text: String) -> void:
    var temp_dir: DirAccess = DirAccess.open(CS_PATHS.SWITCH_DIR)
    for file_path: String in temp_dir.get_files():
        # TODO: handle .gd and .gd.uid
        if file_path.contains(prev_text) and file_path.ends_with(".gd"):
            var file: FileAccess = FileAccess.open(CS_PATHS.SWITCH_DIR + file_path, FileAccess.READ_WRITE)
            var file_content: String = file.get_as_text().replace(prev_text, current_text)
            file.store_string(file_content)
            file.close()
            var new_path: String = file_path.replace(prev_text, current_text)
            temp_dir.rename(file_path, new_path)

    # if cs_config.is_auto_updating:
    #     channel_debug.dispatch_channel_edits(current_text, prev_text, parent_text)
    # else:
    #     channel_debug.update_alerts(channel_tree.get_channel_map())


# func _load_instance_map() -> Dictionary:
#     if not FileAccess.file_exists(CS_PATHS.INSTANCE_STORE):
#         return {}

#     var file: FileAccess = FileAccess.open(CS_PATHS.INSTANCE_STORE, FileAccess.READ)
#     var instance_map: Dictionary = JSON.to_native(JSON.parse_string(file.get_as_text()), true)
#     file.close()
#     return instance_map


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


# func _on_instance_map_changed(new_map: Dictionary) -> void:
#     var file: FileAccess = FileAccess.open(CS_PATHS.INSTANCE_STORE, FileAccess.WRITE)
#     file.store_string(JSON.stringify(JSON.from_native(new_map, true), "\t"))
#     file.close()

#     channel_debug.update_alerts(channel_tree.get_channel_map())


func _on_channel_map_changed(channel_map: Dictionary) -> void:
    var file: FileAccess = FileAccess.open(CS_PATHS.CHANNEL_STORE, FileAccess.WRITE)
    file.store_string(JSON.stringify(JSON.from_native(channel_map, true), "\t"))
    file.close()

    # TODO: differentiate between filling options and resetting options
    # switchboard.fill_options(channel_map)
    _update_switch_scripts(channel_map)
    # channel_debug.update_alerts(channel_map)


func _update_switch_scripts(channel_map: Dictionary) -> void:
    var temp_dir: DirAccess = DirAccess.open(CS_PATHS.SWITCH_DIR)
    var file_paths: Array = temp_dir.get_files()
    var filenames: Array = file_paths.map(func(x): return x.replace(CS_PATHS.SWITCH_DIR, "").replace(".gd", ""))
    var channel_names: Array = channel_map.keys()

    var retired_filenames: Array = filenames.filter(func(x): return not channel_names.has(x))
    for filename: String in retired_filenames:
        temp_dir.remove(CS_PATHS.SWITCH_DIR + filename + ".gd")

    # var missing_filenames: Array = channel_names.filter(func(x): return not filenames.has(x))
    var missing_filenames: Array = channel_map.keys()
    for filename: String in missing_filenames:
        var file: FileAccess = FileAccess.open(CS_PATHS.SWITCH_DIR + filename + ".gd", FileAccess.WRITE)
        file.store_string(
            script_writer.build_script(filename, channel_map[filename])
        )
        file.close()


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
    channel_tab.show()
    settings_button.show()
    lock_button.show()


func _on_debug_button_pressed() -> void:
    channel_tab.hide()
    settings_button.hide()
    lock_button.hide()
    channel_debug.show()


func _on_channel_settings_auto_update_toggled(toggled_on: bool) -> void:
    cs_config.is_auto_updating = toggled_on
    _save_config()