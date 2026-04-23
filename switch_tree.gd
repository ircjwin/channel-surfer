@tool
extends Tree


# nothing_selected emits when left-click doesn't occur on Tree
# empty_clicked emits when mouse clicks in empty space of Tree
# snake_case for param names, universal type case
# whitespace between param and type could be useful for StructuredTextParser
# set_suffix could also provide type
# get_selected_column for determining param or type

# Save sorted array of types and built-in classes
# Global class list has to be checked each edit
# Global class list might be sorted already
# Clear then add items to PopupMenu as user types

# Any click on the suggestions popup should probably select
# Following hover should probably check mouse visibility

const VARIANT_TYPES = [
		TYPE_BOOL,
		TYPE_INT,
		TYPE_FLOAT,
		TYPE_STRING,
		TYPE_VECTOR2,
		TYPE_VECTOR2I,
		TYPE_RECT2,
		TYPE_RECT2I,
		TYPE_VECTOR3,
		TYPE_VECTOR3I,
		TYPE_TRANSFORM2D,
		TYPE_VECTOR4,
		TYPE_VECTOR4I,
		TYPE_PLANE,
		TYPE_QUATERNION,
		TYPE_AABB,
		TYPE_BASIS,
		TYPE_TRANSFORM3D,
		TYPE_PROJECTION,
		TYPE_COLOR,
		TYPE_STRING_NAME,
		TYPE_NODE_PATH,
		TYPE_RID,
		TYPE_OBJECT,
		TYPE_CALLABLE,
		TYPE_SIGNAL,
		TYPE_DICTIONARY,
		TYPE_ARRAY,
		TYPE_PACKED_BYTE_ARRAY,
		TYPE_PACKED_INT32_ARRAY,
		TYPE_PACKED_INT64_ARRAY,
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_PACKED_FLOAT64_ARRAY,
		TYPE_PACKED_STRING_ARRAY,
		TYPE_PACKED_VECTOR2_ARRAY,
		TYPE_PACKED_VECTOR3_ARRAY,
		TYPE_PACKED_COLOR_ARRAY,
		TYPE_PACKED_VECTOR4_ARRAY,
]

const NEW_CHANNEL_TEXT: String = "new_method"
const NEW_PARAM_TEXT: String = "new_paramater"
const ADD_MAIN_TEXT: String = "New Method..."
const ADD_SUB_TEXT: String = "New Parameter..."
const ADD_MAIN_COLOR: Color = Color(0, 0, 0, 0.4)
const ADD_SUB_COLOR: Color = Color(0, 0, 0, 0.2)
const FIRST_COLUMN: int = 0
const SECOND_COLUMN: int = 1
const DEV_CHANNEL_PREFIX: String = "cs_dev"
const COMPONENT_GROUP: String = DEV_CHANNEL_PREFIX + "_component"

var prev_item_text: String = ""
var prev_hovered_item: TreeItem = null
var is_hovering: bool = false
var is_locked: bool = false
var collapsed_items: Array[bool]
var suggestions_array: Array

@onready var add_item_icon = get_theme_icon("Add", &"EditorIcons")
@onready var remove_item_icon = get_theme_icon("Remove", &"EditorIcons")
@onready var tree_popup: Popup = find_child("*Popup*", true, false)
@onready var tree_v_box: VBoxContainer = find_child("*VBoxContainer*", true, false)
@onready var tree_line: LineEdit = find_child("*LineEdit*", true, false)
@onready var tree_line_script: Script = preload("res://tree_line.gd")
# @onready var suggestions_item_list: ItemList = find_child("ItemList", true, true)
@onready var suggestions_item_list: ItemList = ItemList.new()
@onready var suggestions_item_list_panel: StyleBoxFlat = suggestions_item_list.get_theme_stylebox("panel").duplicate()


func _ready() -> void:
	columns = 2
	set_column_expand(0, true)
	set_column_expand(1, true)
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 1)

	item_mouse_selected.connect(_on_item_mouse_selected)
	item_edited.connect(_on_item_edited)
	item_activated.connect(_on_item_activated)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_clicked.connect(_on_button_clicked)

	clear()
	var root: TreeItem = create_item()
	hide_root = true
	_create_item_adder(root, ADD_MAIN_TEXT, ADD_MAIN_COLOR)
	_build_autocomplete()

	tree_line.size_flags_vertical = Control.SIZE_FILL
	tree_line.set_script(tree_line_script)
	tree_line.text_changed.connect(_on_text_changed)

	suggestions_item_list.empty_clicked.connect(_on_suggestions_item_list_empty_clicked)
	suggestions_item_list.item_selected.connect(_on_suggestions_item_list_item_selected)

	suggestions_item_list_panel.border_width_top = 1
	suggestions_item_list_panel.border_width_bottom = 1
	suggestions_item_list_panel.border_width_right = 1
	suggestions_item_list_panel.border_width_left = 1

	suggestions_item_list.add_theme_stylebox_override("panel", suggestions_item_list_panel)

	tree_popup.popup_hide.connect(_on_tree_popup_popup_hide)


func _process(_delta: float) -> void:
	if suggestions_item_list.has_focus():
		tree_line.grab_focus()


func _build_autocomplete() -> void:
	# Search suggestions then sort results; probably don't need local array
	suggestions_array = VARIANT_TYPES.map(func(x): return type_string(x))
	suggestions_array.append_array(ClassDB.get_class_list())
	suggestions_array.sort()

	# suggestions_item_list.reparent(tree_v_box)
	tree_v_box.add_child(suggestions_item_list)
	suggestions_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suggestions_item_list.hide()


func _on_tree_popup_popup_hide() -> void:
	suggestions_item_list.clear()
	suggestions_item_list.hide()


func _on_suggestions_item_list_empty_clicked(_at_position: Vector2, _mouse_button_index: int) -> void:
	pass


func _on_suggestions_item_list_item_selected(_index: int) -> void:
	pass


func _on_item_activated() -> void:
	if is_locked:
		return

	var edited_column: int = get_selected_column()
	var selected_item: TreeItem = get_selected()
	var item_parent: TreeItem = selected_item.get_parent()

	if selected_item != item_parent.get_child(-1):
		prev_item_text = selected_item.get_text(edited_column).to_snake_case()
		selected_item.set_editable(edited_column, true)
		edit_selected()
		tree_line.custom_minimum_size = tree_v_box.size


func _on_text_changed(new_text: String) -> void:
	if get_selected_column() != SECOND_COLUMN or get_selected().get_parent() == get_root():
		return

	suggestions_item_list.clear()
	suggestions_item_list.hide()
	tree_popup.reset_size()

	if new_text.is_empty():
		return

	var result: Array
	for suggestion in suggestions_array:
		if suggestion.containsn(new_text):
			result.append(suggestion)

	for suggestion in ProjectSettings.get_global_class_list():
		if suggestion["class"].containsn(new_text):
			result.append(str(suggestion["class"]))

	if result.is_empty():
		return

	result.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)

	for suggestion in result:
		suggestions_item_list.add_item(suggestion)

	suggestions_item_list.show()
	await get_tree().process_frame
	var item_height: int = round(suggestions_item_list.get_item_rect(0).size.y) + suggestions_item_list.get_theme_constant("v_separation", &"ItemList")
	var visible_items: int = clamp(len(result), 1, 5)
	suggestions_item_list.custom_minimum_size.y = visible_items * item_height
	tree_v_box.reset_size()
	await get_tree().process_frame
	tree_popup.reset_size()


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
	var hovered_item: TreeItem = get_item_at_position(get_local_mouse_position())

	if hovered_item == prev_hovered_item:
		return

	if prev_hovered_item:
		prev_hovered_item.clear_buttons()

	if hovered_item and not _is_adder(hovered_item):
		hovered_item.add_button(SECOND_COLUMN, remove_item_icon)

	prev_hovered_item = hovered_item


func _on_item_edited() -> void:
	var edited_item: TreeItem = get_edited()
	var edited_column: int = get_edited_column()
	var edited_item_text: String = edited_item.get_text(edited_column).to_snake_case()

	edited_item.set_editable(edited_column, false)

	if edited_item_text == prev_item_text:
		return

	edited_item.set_text(edited_column, edited_item_text.capitalize())


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
	var channel_text: String = NEW_PARAM_TEXT
	var param_text: String = "new_type"

	if item_parent == get_root():
		channel_text = NEW_CHANNEL_TEXT
		param_text = "args:_0"
		_create_item_adder(new_item, ADD_SUB_TEXT, ADD_SUB_COLOR)
	else:
		_update_arg_count(item_parent)

	new_item.set_text(FIRST_COLUMN, channel_text.capitalize())
	new_item.set_text(SECOND_COLUMN, param_text.capitalize())
	new_item.collapsed = true
	new_item.add_button(SECOND_COLUMN, remove_item_icon)


func _create_item_adder(adder_parent: TreeItem, adder_text: String, adder_bg_color: Color) -> void:
	if is_locked:
		return

	var new_item_adder: TreeItem = create_item(adder_parent)
	new_item_adder.set_icon(FIRST_COLUMN, add_item_icon)
	new_item_adder.set_text(FIRST_COLUMN, adder_text)
	new_item_adder.set_custom_bg_color(FIRST_COLUMN, adder_bg_color)
	new_item_adder.set_custom_bg_color(SECOND_COLUMN, adder_bg_color)
	new_item_adder.set_selectable(SECOND_COLUMN, false)


func _update_arg_count(method_item: TreeItem) -> void:
	var arg_text: String = method_item.get_text(SECOND_COLUMN).to_snake_case()
	var arg_int: int = arg_text.trim_prefix("args:_").to_int()
	arg_int += 1
	var new_arg_text: String = "args:_%d" % arg_int
	method_item.set_text(SECOND_COLUMN, new_arg_text.capitalize())
