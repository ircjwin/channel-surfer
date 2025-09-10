@tool
extends Control


@export var add_item_icon: Texture2D
@export var remove_item_icon: Texture2D
@export var channel_map: ChannelMap

@onready var channel_tree: Tree = %ChannelTree

const ADD_MAIN_TEXT: String = "New Main..."
const ADD_SUB_TEXT: String = "New Sub..."
const ADD_MAIN_COLOR: Color = Color(0, 0, 0, 0.4)
const ADD_SUB_COLOR: Color = Color(0, 0, 0, 0.2)
const FIRST_COLUMN: int = 0
const NEW_CHANNEL_TEXT: String = "New Channel"

var prev_item_text: String = ""
var prev_hovered_item: TreeItem = null
var is_hovering: bool = false

## Consider checks for button click

func _ready() -> void:
    channel_tree.item_mouse_selected.connect(_on_item_mouse_selected)
    channel_tree.item_edited.connect(_on_item_edited)
    channel_tree.item_activated.connect(_on_item_activated)
    channel_tree.mouse_entered.connect(_on_mouse_entered)
    channel_tree.mouse_exited.connect(_on_mouse_exited)
    channel_tree.button_clicked.connect(_on_button_clicked)
    _build_tree()

func _process(delta: float) -> void:
    if is_hovering:
        _follow_hover()

func _build_tree() -> void:
    channel_tree.clear()
    var root = channel_tree.create_item()
    channel_tree.hide_root = true

    for main_channel: String in channel_map.legend:
        var new_child = channel_tree.create_item(root)
        new_child.set_text(FIRST_COLUMN, main_channel)
        for sub_channel: String in channel_map.legend[main_channel]:
            var new_grandchild = channel_tree.create_item(new_child)
            new_grandchild.set_text(FIRST_COLUMN, sub_channel)
        _create_item_adder(new_child)
        new_child.collapsed = true
    _create_item_adder(root, true)

func _on_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> void:
    if mouse_button_index == MOUSE_BUTTON_LEFT:
        var item_parent: TreeItem = item.get_parent()
        if item_parent == channel_tree.get_root():
            channel_map.legend.erase(item.get_text(FIRST_COLUMN))
        else:
            channel_map.legend[item_parent.get_text(FIRST_COLUMN)].erase(item.get_text(FIRST_COLUMN))
        item.free()
        ResourceSaver.save(channel_map)

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
    var hovered_item: TreeItem = channel_tree.get_item_at_position(channel_tree.get_local_mouse_position())
    if hovered_item == prev_hovered_item:
        return
    if prev_hovered_item:
        prev_hovered_item.clear_buttons()
    if hovered_item and not _is_adder(hovered_item):
        hovered_item.add_button(FIRST_COLUMN, remove_item_icon)
    prev_hovered_item = hovered_item

func _on_item_activated() -> void:
    var selected_item: TreeItem = channel_tree.get_selected()
    var item_parent: TreeItem = selected_item.get_parent()
    if selected_item != item_parent.get_child(-1):
        prev_item_text = selected_item.get_text(FIRST_COLUMN)
        selected_item.set_editable(FIRST_COLUMN, true)
        channel_tree.edit_selected()

func _on_item_edited() -> void:
    var tree_item: TreeItem = channel_tree.get_edited()
    var item_parent: TreeItem = tree_item.get_parent()
    var new_text: String = tree_item.get_text(FIRST_COLUMN)
    if new_text == prev_item_text:
        prev_item_text = ""
        return
    var unique_text: String = _enforce_unique(item_parent, new_text)
    if unique_text != new_text:
        tree_item.set_text(FIRST_COLUMN, unique_text)
        new_text = unique_text
    if item_parent == channel_tree.get_root():
        channel_map.legend.set(new_text, channel_map.legend[prev_item_text])
        channel_map.legend.erase(prev_item_text)
    else:
        channel_map.legend[item_parent.get_text(FIRST_COLUMN)] = \
            channel_map.legend[item_parent.get_text(FIRST_COLUMN)].map(
                func(x: String) -> String:
                    if x == prev_item_text:
                        return new_text
                    else:
                        return x
                    )
    prev_item_text = ""
    tree_item.set_editable(FIRST_COLUMN, false)
    ResourceSaver.save(channel_map)

func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
    if mouse_button_index == MOUSE_BUTTON_LEFT:
        var selected_item: TreeItem = channel_tree.get_item_at_position(mouse_position)
        var item_parent: TreeItem = selected_item.get_parent()
        if selected_item == item_parent.get_child(-1):
            var item_index: int = item_parent.get_child_count() - 1
            var is_main: bool = item_parent == channel_tree.get_root()
            _add_tree_item.call_deferred(item_parent, item_index, is_main)

func _enforce_unique(item_parent: TreeItem, current_text: String) -> String:
    var siblings: Array[String]
    var channel_array: Array[String]
    var counter: int = 0
    var is_unique: bool = true
    if item_parent == channel_tree.get_root():
        channel_array = channel_map.legend.keys()
    else:
        channel_array = channel_map.legend[item_parent.get_text(FIRST_COLUMN).to_lower()]
    siblings = channel_array.duplicate()
    siblings.sort()
    for sibling_name: String in siblings:
        if sibling_name.begins_with(current_text):
            is_unique = false
            var str_tokens: PackedStringArray= sibling_name.split(" ")
            if str_tokens[-1].is_valid_int():
                var temp_counter: int = str_tokens[-1].to_int()
                if temp_counter - 1 == counter:
                    counter = temp_counter
    if is_unique:
        return current_text
    else:
        counter += 1
        return current_text + " " + str(counter)

func _add_tree_item(item_parent: TreeItem, item_index: int, is_main: bool) -> void:
    var new_item: TreeItem = channel_tree.create_item(item_parent, item_index)
    var channel_text = _enforce_unique(item_parent, NEW_CHANNEL_TEXT)
    var counter = 1
    if is_main:
        while channel_map.legend.has(channel_text):
            channel_text = NEW_CHANNEL_TEXT + " " + str(counter)
            counter += 1
        channel_map.legend.set(channel_text, [])
        _create_item_adder(new_item)
    else:
        while channel_map.legend[item_parent.get_text(FIRST_COLUMN)].has(channel_text):
            channel_text = NEW_CHANNEL_TEXT + " " + str(counter)
            counter += 1
        channel_map.legend[item_parent.get_text(FIRST_COLUMN)].append(channel_text)
    new_item.set_text(FIRST_COLUMN, channel_text)
    new_item.collapsed = true
    ResourceSaver.save(channel_map)

func _create_item_adder(adder_parent: TreeItem, is_root: bool = false) -> void:
    var new_item_adder: TreeItem = channel_tree.create_item(adder_parent)
    new_item_adder.set_icon(FIRST_COLUMN, add_item_icon)
    if is_root:
        new_item_adder.set_text(FIRST_COLUMN, ADD_MAIN_TEXT)
        new_item_adder.set_custom_bg_color(FIRST_COLUMN, ADD_MAIN_COLOR)
    else:
        new_item_adder.set_text(FIRST_COLUMN, ADD_SUB_TEXT)
        new_item_adder.set_custom_bg_color(FIRST_COLUMN, ADD_SUB_COLOR)
