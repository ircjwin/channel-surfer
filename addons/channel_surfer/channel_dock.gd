@tool
extends Control


@export var add_item_icon: Texture2D
@export var remove_item_icon: Texture2D

@onready var channel_tree: Tree = %ChannelTree

const ADD_MAIN_TEXT: String = "New Main..."
const ADD_SUB_TEXT: String = "New Sub..."
const ADD_MAIN_COLOR: Color = Color(0, 0, 0, 0.4)
const ADD_SUB_COLOR: Color = Color(0, 0, 0, 0.2)
const FIRST_COLUMN: int = 0
const NEW_CHANNEL_TEXT: String = "New Channel"

var prev_hovered_item: TreeItem = null
var is_hovering: bool = false

## Consider checks for button click

func _ready() -> void:
    _build_tree()

func _process(delta: float) -> void:
    if is_hovering:
        _follow_hover()

func _build_tree() -> void:
    channel_tree.clear()
    var root = channel_tree.create_item()
    channel_tree.hide_root = true

    var child1 = channel_tree.create_item(root)
    var child2 = channel_tree.create_item(root)
    var new_main = channel_tree.create_item(root)
    var new_sub_1 = channel_tree.create_item(child1)
    var new_sub_2 = channel_tree.create_item(child2)

    child1.set_text(FIRST_COLUMN, "Child1")
    child2.set_text(FIRST_COLUMN, "Child2")
    new_sub_1.set_text(FIRST_COLUMN, ADD_SUB_TEXT)
    new_sub_2.set_text(FIRST_COLUMN, ADD_SUB_TEXT)
    new_main.set_text(FIRST_COLUMN, ADD_MAIN_TEXT)

    new_main.set_icon(FIRST_COLUMN, add_item_icon)
    new_sub_1.set_icon(FIRST_COLUMN, add_item_icon)
    new_sub_2.set_icon(FIRST_COLUMN, add_item_icon)

    new_main.set_custom_bg_color(FIRST_COLUMN, ADD_MAIN_COLOR)
    new_sub_1.set_custom_bg_color(FIRST_COLUMN, ADD_SUB_COLOR)
    new_sub_2.set_custom_bg_color(FIRST_COLUMN, ADD_SUB_COLOR)

    channel_tree.item_mouse_selected.connect(_on_item_mouse_selected)
    channel_tree.item_edited.connect(_on_item_edited)
    channel_tree.item_activated.connect(_on_item_activated)
    channel_tree.mouse_entered.connect(_on_mouse_entered)
    channel_tree.mouse_exited.connect(_on_mouse_exited)
    channel_tree.button_clicked.connect(_on_button_clicked)

func _on_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> void:
    if mouse_button_index == MOUSE_BUTTON_LEFT:
        item.free()

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
        selected_item.set_editable(FIRST_COLUMN, true)
        channel_tree.edit_selected()

func _on_item_edited() -> void:
    var tree_item: TreeItem = channel_tree.get_edited()
    tree_item.set_editable(FIRST_COLUMN, false)

func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
    if mouse_button_index == MOUSE_BUTTON_LEFT:
        var selected_item: TreeItem = channel_tree.get_item_at_position(mouse_position)
        var item_parent: TreeItem = selected_item.get_parent()
        if selected_item == item_parent.get_child(-1):
            var item_index: int = item_parent.get_child_count() - 1
            var is_main: bool = item_parent == channel_tree.get_root()
            _add_tree_item.call_deferred(item_parent, item_index, is_main)

func _add_tree_item(item_parent: TreeItem, item_index: int, is_main: bool) -> void:
    var new_item: TreeItem = channel_tree.create_item(item_parent, item_index)
    new_item.set_text(FIRST_COLUMN, NEW_CHANNEL_TEXT)
    if is_main:
        _create_item_adder(new_item)

func _create_item_adder(adder_parent: TreeItem, is_root: bool = false) -> void:
    var new_item_adder: TreeItem = channel_tree.create_item(adder_parent)
    new_item_adder.set_icon(FIRST_COLUMN, add_item_icon)
    if is_root:
        new_item_adder.set_text(FIRST_COLUMN, ADD_MAIN_TEXT)
        new_item_adder.set_custom_bg_color(FIRST_COLUMN, ADD_MAIN_COLOR)
    else:
        new_item_adder.set_text(FIRST_COLUMN, ADD_SUB_TEXT)
        new_item_adder.set_custom_bg_color(FIRST_COLUMN, ADD_SUB_COLOR)
