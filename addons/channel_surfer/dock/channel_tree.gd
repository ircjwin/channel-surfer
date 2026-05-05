@tool
extends Tree


signal channel_map_changed(changed_map: Dictionary)
signal channel_edited(new_name: String, old_name: String, parent_name: String)
signal channel_rmb_selected(name: String)

const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const SWITCHBOARD_TYPE: Resource = preload(CS_PATHS.SWITCHBOARD_TYPE)
const NEW_CHANNEL_TEXT: String = "new_channel"
const ADD_MAIN_TEXT: String = "New Main..."
const ADD_SUB_TEXT: String = "New Sub..."
const ADD_MAIN_COLOR: Color = Color(0, 0, 0, 0.4)
const ADD_SUB_COLOR: Color = Color(0, 0, 0, 0.2)
const FIRST_COLUMN: int = 0
const DEV_CHANNEL_PREFIX: String = "cs_dev"
const COMPONENT_GROUP: String = DEV_CHANNEL_PREFIX + "_component"

var channel_map: Dictionary = {}
var prev_item_text: String = ""
var prev_hovered_item: TreeItem = null
var is_hovering: bool = false
var is_locked: bool = false
var collapsed_items: Array[bool]

@onready var switchboard: SWITCHBOARD_TYPE = %Switchboard
@onready var add_item_icon = get_theme_icon("Add", &"EditorIcons")
@onready var remove_item_icon = get_theme_icon("Remove", &"EditorIcons")

#TODO: use unique %
@onready var channel_line_edit: LineEdit = $"../HBoxContainer/LineEdit"


func _ready() -> void:
    hide_root = true

    channel_line_edit.keep_editing_on_text_submit = true
    item_mouse_selected.connect(_on_item_mouse_selected)
    item_edited.connect(_on_item_edited)
    item_activated.connect(_on_item_activated)
    button_clicked.connect(_on_button_clicked)
    channel_line_edit.text_submitted.connect(_on_channel_line_edit_text_submitted)


func _on_channel_line_edit_text_submitted(new_text: String) -> void:
    channel_line_edit.clear()
    _add_tree_item(new_text)


func get_channel_map() -> Dictionary:
    return channel_map


func set_surfer_channel_map(surfer_node: ChannelSurfer) -> void:
    surfer_node.set_channel_map(channel_map)


func dispatch_channel_map() -> void:
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE,
        COMPONENT_GROUP, "set_channel_map", channel_map)


func build_tree(new_map: Dictionary = {}) -> void:
    clear()
    create_item()

    if not new_map.is_empty():
        channel_map = new_map

    for main_channel: String in channel_map:
        var new_child = create_item()
        new_child.set_text(FIRST_COLUMN, main_channel.capitalize())
        new_child.add_button(FIRST_COLUMN, remove_item_icon)


func uproot() -> void:
    channel_map.clear()
    build_tree()

    dispatch_channel_map()
    channel_map_changed.emit(channel_map)


func _on_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> void:
    if mouse_button_index == MOUSE_BUTTON_LEFT:
        var item_text: String = item.get_text(FIRST_COLUMN).to_snake_case()

        channel_map.erase(item_text)
        item.free()

        dispatch_channel_map()
        channel_map_changed.emit(channel_map)


func _on_item_activated() -> void:
    if is_locked:
        return

    var selected_item: TreeItem = get_selected()

    prev_item_text = selected_item.get_text(FIRST_COLUMN).to_snake_case()
    selected_item.set_editable(FIRST_COLUMN, true)
    edit_selected()


func _on_item_edited() -> void:
    var edited_item: TreeItem = get_edited()
    var item_parent: TreeItem = edited_item.get_parent()
    var edited_item_text: String = edited_item.get_text(FIRST_COLUMN).to_snake_case()
    var item_parent_text: String = ""
    var unique_text: String

    edited_item.set_editable(FIRST_COLUMN, false)

    if edited_item_text == prev_item_text:
        return

    unique_text = _make_unique(edited_item_text, channel_map.keys())
    channel_map.set(unique_text, channel_map[prev_item_text])
    channel_map.erase(prev_item_text)

    edited_item.set_text(FIRST_COLUMN, unique_text.capitalize())

    dispatch_channel_map()
    channel_map_changed.emit(channel_map)
    channel_edited.emit(unique_text, prev_item_text, item_parent_text)


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
    if is_locked:
        return

    if mouse_button_index == MOUSE_BUTTON_RIGHT:
        var selected_item: TreeItem = get_item_at_position(mouse_position)

        # Need a method in switchboard to handle this
        switchboard.main_option_button.select(selected_item.get_index() + 1)

        channel_rmb_selected.emit(selected_item.get_text(FIRST_COLUMN).to_snake_case())


func _make_unique(new_text: String, siblings: Array) -> String:
    var sorted_siblings: Array = siblings.duplicate_deep()
    sorted_siblings.sort()
    var counter: int = 0

    for sibling_text: String in sorted_siblings:
        if new_text == sibling_text:
            counter += 1
            continue

        var last_slice_index: int = sibling_text.get_slice_count("_") - 1
        var sibling_end: String = sibling_text.get_slice("_", last_slice_index)
        if sibling_end.is_valid_int() and new_text + "_" + sibling_end == sibling_text:
            if counter == sibling_end.to_int():
                counter += 1

    return new_text if counter <= 0 else new_text + "_" + str(counter)


func _add_tree_item(channel_text: String) -> void:
    var new_item: TreeItem = create_item(get_root())

    channel_text = channel_text.strip_edges().to_snake_case()

    if channel_text.is_empty():
        channel_text = NEW_CHANNEL_TEXT

    channel_text = _make_unique(channel_text, channel_map.keys())
    channel_map.set(channel_text, {})

    new_item.set_text(FIRST_COLUMN, channel_text.capitalize())
    new_item.add_button(FIRST_COLUMN, remove_item_icon)

    dispatch_channel_map()
    channel_map_changed.emit(channel_map)
