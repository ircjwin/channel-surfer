@tool
class_name ChannelTree
extends Tree


signal channel_map_changed(changed_map: Dictionary)
signal channel_edited(new_name: String, old_name: String, parent_name: String)

@export var add_item_icon: Texture2D
@export var remove_item_icon: Texture2D

const NEW_CHANNEL_TEXT: String = "new_channel"
const ADD_MAIN_TEXT: String = "New Main..."
const ADD_SUB_TEXT: String = "New Sub..."
const ADD_MAIN_COLOR: Color = Color(0, 0, 0, 0.4)
const ADD_SUB_COLOR: Color = Color(0, 0, 0, 0.2)
const FIRST_COLUMN: int = 0

var channel_map: Dictionary = {}
var prev_item_text: String = ""
var prev_hovered_item: TreeItem = null
var is_hovering: bool = false
var is_locked: bool = false


func _enter_tree() -> void:
    add_to_group(ChannelSurfer.MAP_GROUP)


func _ready() -> void:
    item_mouse_selected.connect(_on_item_mouse_selected)
    item_edited.connect(_on_item_edited)
    item_activated.connect(_on_item_activated)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    button_clicked.connect(_on_button_clicked)


func _process(_delta: float) -> void:
    if not is_locked and is_hovering:
        _follow_hover()


func get_channel_map() -> Dictionary:
    return channel_map


func dispatch_channel_map() -> void:
    get_tree().call_group_flags(
        SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE,
        ChannelSurfer.COMPONENT_GROUP, "set_channel_map", channel_map)


func build_tree(new_map: Dictionary = {}) -> void:
    clear()
    var root: TreeItem = create_item()
    hide_root = true

    if not new_map.is_empty():
        channel_map = new_map

    for main_channel: String in channel_map:
        var new_child = create_item(root)
        new_child.set_text(FIRST_COLUMN, main_channel.capitalize())

        for sub_channel: String in channel_map[main_channel]:
            var new_grandchild = create_item(new_child)
            new_grandchild.set_text(FIRST_COLUMN, sub_channel.capitalize())

        _create_item_adder(new_child, ADD_SUB_TEXT, ADD_SUB_COLOR)
        new_child.collapsed = true

    _create_item_adder(root, ADD_MAIN_TEXT, ADD_MAIN_COLOR)


func _on_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> void:
    if mouse_button_index == MOUSE_BUTTON_LEFT:
        var item_parent: TreeItem = item.get_parent()
        var item_text: String = item.get_text(FIRST_COLUMN).to_snake_case()

        if item_parent == get_root():
            channel_map.erase(item_text)
        else:
            var parent_text: String = item_parent.get_text(FIRST_COLUMN).to_snake_case()
            channel_map[parent_text].erase(item_text)

        item.free()

        dispatch_channel_map()
        channel_map_changed.emit(channel_map)


func _on_mouse_entered() -> void:
    is_hovering = true


func _on_mouse_exited() -> void:
    if prev_hovered_item:
        prev_hovered_item.clear_buttons()
        prev_hovered_item = null

    is_hovering = false


func _is_adder(item: TreeItem) -> bool:
    var item_parent: TreeItem = item.get_parent()

    if item == item_parent.get_child(-1):
        return true

    return false


func _follow_hover() -> void:
    var hovered_item: TreeItem = get_item_at_position(get_local_mouse_position())

    if hovered_item == prev_hovered_item:
        return

    if prev_hovered_item:
        prev_hovered_item.clear_buttons()

    if hovered_item and not _is_adder(hovered_item):
        hovered_item.add_button(FIRST_COLUMN, remove_item_icon)

    prev_hovered_item = hovered_item


func _on_item_activated() -> void:
    if is_locked:
        return

    var selected_item: TreeItem = get_selected()
    var item_parent: TreeItem = selected_item.get_parent()

    if selected_item != item_parent.get_child(-1):
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

    if item_parent == get_root():
        unique_text = _make_unique(edited_item_text, channel_map.keys())
        channel_map.set(unique_text, channel_map[prev_item_text])
        channel_map.erase(prev_item_text)
    else:
        item_parent_text = item_parent.get_text(FIRST_COLUMN).to_snake_case()
        unique_text = _make_unique(edited_item_text, channel_map[item_parent_text])
        var edited_item_index: int = edited_item.get_index()
        channel_map[item_parent_text][edited_item_index] = unique_text

    edited_item.set_text(FIRST_COLUMN, unique_text.capitalize())

    dispatch_channel_map()
    channel_map_changed.emit(channel_map)
    channel_edited.emit(unique_text, prev_item_text, item_parent_text)


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
    if is_locked:
        return

    if mouse_button_index == MOUSE_BUTTON_LEFT:
        var selected_item: TreeItem = get_item_at_position(mouse_position)
        var item_parent: TreeItem = selected_item.get_parent()

        if selected_item == item_parent.get_child(-1):
            _add_tree_item.call_deferred(item_parent, selected_item.get_index())


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


func _add_tree_item(item_parent: TreeItem, item_index: int) -> void:
    var new_item: TreeItem = create_item(item_parent, item_index)
    var channel_text: String

    if item_parent == get_root():
        channel_text = _make_unique(NEW_CHANNEL_TEXT, channel_map.keys())
        channel_map.set(channel_text, [])
        _create_item_adder(new_item, ADD_SUB_TEXT, ADD_SUB_COLOR)
    else:
        var parent_text: String = item_parent.get_text(FIRST_COLUMN).to_snake_case()
        channel_text = _make_unique(NEW_CHANNEL_TEXT, channel_map[parent_text])
        channel_map[parent_text].append(channel_text)

    new_item.set_text(FIRST_COLUMN, channel_text.capitalize())
    new_item.collapsed = true

    dispatch_channel_map()
    channel_map_changed.emit(channel_map)


func _create_item_adder(adder_parent: TreeItem, adder_text: String, adder_bg_color: Color) -> void:
    if is_locked:
        return

    var new_item_adder: TreeItem = create_item(adder_parent)
    new_item_adder.set_icon(FIRST_COLUMN, add_item_icon)
    new_item_adder.set_text(FIRST_COLUMN, adder_text)
    new_item_adder.set_custom_bg_color(FIRST_COLUMN, adder_bg_color)

