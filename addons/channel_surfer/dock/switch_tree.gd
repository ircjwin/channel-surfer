@tool
extends Tree


# TODO: make _add_tree_item update and dispatch local data

signal switchboard_changed(new_board: Dictionary)

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

const NEW_METHOD_TEXT: String = "new_method"
const NEW_PARAM_TEXT: String = "new_paramater"
const ADD_METHOD_TEXT: String = "New Method..."
const ADD_PARAM_TEXT: String = "New Parameter..."
const NEW_TYPE_TEXT: String = "Variant"
const ADD_METHOD_COLOR: Color = Color(0, 0, 0, 0.4)
const ADD_PARAM_COLOR: Color = Color(0, 0, 0, 0.2)
const FIRST_COLUMN: int = 0
const SECOND_COLUMN: int = 1
const DEV_CHANNEL_PREFIX: String = "cs_dev"
const COMPONENT_GROUP: String = DEV_CHANNEL_PREFIX + "_component"

var prev_item_text: String = ""
var edited_type_text: String = ""
var is_locked: bool = false
var collapsed_items: Array[bool]
var suggestions_array: Array
var switchboard: Dictionary = {}

@onready var add_item_icon = get_theme_icon("Add", &"EditorIcons")
@onready var remove_item_icon = get_theme_icon("Remove", &"EditorIcons")
@onready var tree_popup: Popup = find_child("*Popup*", true, false)
@onready var tree_v_box: VBoxContainer = find_child("*VBoxContainer*", true, false)
@onready var tree_line: LineEdit = find_child("*LineEdit*", true, false)
@onready var tree_line_script: Script = preload("res://addons/channel_surfer/dock/tree_line.gd")
@onready var suggestions_item_list: ItemList = ItemList.new()
@onready var suggestions_item_list_panel: StyleBoxFlat = suggestions_item_list.get_theme_stylebox("panel").duplicate()


func _ready() -> void:
	hide_root = true
	columns = 2
	set_column_expand(0, true)
	set_column_expand(1, true)
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 1)

	_build_autocomplete()

	tree_line.size_flags_vertical = Control.SIZE_FILL
	tree_line.set_script(tree_line_script)

	suggestions_item_list_panel.border_width_top = 1
	suggestions_item_list_panel.border_width_bottom = 1
	suggestions_item_list_panel.border_width_right = 1
	suggestions_item_list_panel.border_width_left = 1
	suggestions_item_list.add_theme_stylebox_override("panel", suggestions_item_list_panel)
	suggestions_item_list.select_mode = ItemList.SELECT_SINGLE

	item_mouse_selected.connect(_on_item_mouse_selected)
	item_edited.connect(_on_item_edited)
	item_activated.connect(_on_item_activated)
	button_clicked.connect(_on_button_clicked)
	tree_popup.popup_hide.connect(_on_tree_popup_popup_hide)
	tree_popup.window_input.connect(_on_tree_popup_window_input)
	tree_line.text_changed.connect(_on_text_changed)
	suggestions_item_list.item_clicked.connect(_on_suggestions_item_list_item_clicked)


func _process(_delta: float) -> void:
	if suggestions_item_list.has_focus():
		tree_line.grab_focus()


func _on_tree_popup_window_input(event: InputEvent) -> void:
	if suggestions_item_list.visible and suggestions_item_list.is_anything_selected():
		var index: int = suggestions_item_list.get_selected_items()[0]
		if event.is_action_pressed("ui_text_caret_up"):
			if index > 0:
				index -= 1
				suggestions_item_list.select(index)
		elif event.is_action_pressed("ui_text_caret_down"):
			if index < suggestions_item_list.item_count - 1:
				index += 1
				suggestions_item_list.select(index)
		edited_type_text = suggestions_item_list.get_item_text(index)
		suggestions_item_list.ensure_current_is_visible()


func _on_suggestions_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		edited_type_text = suggestions_item_list.get_item_text(index)
		tree_line.text_submitted.emit(edited_type_text)


func _read_tree_item(item_parent: TreeItem, item_text_1: String, item_text_2: String = "") -> TreeItem:
	var new_item: TreeItem = create_item(item_parent)

	if item_parent == get_root():
		item_text_2 = "args: 0"
	else:
		_inc_arg_count(item_parent)

	new_item.collapsed = true
	new_item.set_text(FIRST_COLUMN, item_text_1)
	new_item.set_text(SECOND_COLUMN, item_text_2)
	new_item.add_button(SECOND_COLUMN, remove_item_icon)

	return new_item


func build_tree(new_board: Dictionary = {}) -> void:
	clear()
	create_item()

	if not new_board.is_empty():
		switchboard = new_board

	for method_switch: String in switchboard.keys():
		var new_method: TreeItem = _read_tree_item(get_root(), method_switch)
		for param_switch: Dictionary in switchboard[method_switch]:
			_read_tree_item(new_method, param_switch.get_or_add("name"), param_switch.get_or_add("type"))
		_create_item_adder(new_method, ADD_PARAM_TEXT, ADD_PARAM_COLOR)

	_create_item_adder(get_root(), ADD_METHOD_TEXT, ADD_METHOD_COLOR)


func _build_autocomplete() -> void:
	# Search suggestions then sort results; probably don't need local array
	suggestions_array = VARIANT_TYPES.map(func(x): return type_string(x))
	suggestions_array.append_array(ClassDB.get_class_list())
	suggestions_array.append(NEW_TYPE_TEXT)
	suggestions_array.sort()

	tree_v_box.add_child(suggestions_item_list)
	suggestions_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suggestions_item_list.hide()


func _on_tree_popup_popup_hide() -> void:
	suggestions_item_list.clear()
	suggestions_item_list.hide()


func _on_item_activated() -> void:
	if is_locked:
		return

	var edited_column: int = get_selected_column()
	var selected_item: TreeItem = get_selected()
	var item_parent: TreeItem = selected_item.get_parent()

	if selected_item != item_parent.get_child(-1):
		if item_parent != get_root() or edited_column != SECOND_COLUMN:
			prev_item_text = selected_item.get_text(edited_column)
			selected_item.set_editable(edited_column, true)
			edit_selected()

			# Should only need this for col 2
			tree_line.custom_minimum_size = tree_v_box.size


func _on_text_changed(new_text: String) -> void:
	if get_selected().get_parent() == get_root() or get_selected_column() == FIRST_COLUMN:
		return

	suggestions_item_list.clear()
	suggestions_item_list.hide()
	tree_popup.reset_size()
	edited_type_text = ""

	if new_text.is_empty():
		return

	var result: Array
	for suggestion in suggestions_array:
		if suggestion.containsn(new_text):
			result.append(suggestion)

	# TODO: front load suggestions that begin with new text, shortest to longest
	for suggestion in ProjectSettings.get_global_class_list():
		if suggestion["class"].containsn(new_text):
			result.append(str(suggestion["class"]))

	if result.is_empty():
		return

	# TODO: reconsider sorting after adjusting suggestions above
	# result.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	result.sort_custom(func(a, b): return len(a) < len(b))

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
	suggestions_item_list.select(0)
	edited_type_text = suggestions_item_list.get_item_text(0)


func _on_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		var item_parent: TreeItem = item.get_parent()
		if item_parent == get_root():
			switchboard.erase(item.get_text(FIRST_COLUMN))
		else:
			switchboard[item_parent.get_text(FIRST_COLUMN)].remove_at(item.get_index())
			_dec_arg_count(item_parent)

		item.free()
		switchboard_changed.emit(switchboard)


func _is_adder(item: TreeItem) -> bool:
	var item_parent: TreeItem = item.get_parent()

	if item == item_parent.get_child(-1):
		return true

	return false


func _on_item_edited() -> void:
	var edited_item: TreeItem = get_edited()
	var edited_item_parent: TreeItem = edited_item.get_parent()
	var edited_column: int = get_edited_column()
	var edited_item_text: String = edited_item.get_text(edited_column)

	if edited_column == FIRST_COLUMN:
		edited_item_text = edited_item_text.strip_edges().to_snake_case()

	edited_item.set_editable(edited_column, false)

	if edited_item_text == prev_item_text:
		return

	if edited_item_parent == get_root():
		if edited_item_text.is_empty():
			edited_item_text = NEW_METHOD_TEXT

		var method_siblings: Array = switchboard.keys()
		method_siblings.erase(prev_item_text)
		edited_item_text = _make_unique(edited_item_text, method_siblings)

		var param_array: Array = switchboard[prev_item_text]
		switchboard.erase(prev_item_text)
		switchboard.set(edited_item_text, param_array)
	else:
		if edited_item_text.is_empty():
			edited_item_text = NEW_PARAM_TEXT

		var edited_item_parent_text: String = edited_item_parent.get_text(FIRST_COLUMN)
		var param_siblings: Array = switchboard[edited_item_parent_text].map(func(x): return x.name)
		param_siblings.erase(prev_item_text)

		if edited_column == FIRST_COLUMN:
			edited_item_text = _make_unique(edited_item_text, param_siblings)
			switchboard[edited_item_parent_text][edited_item.get_index()].set("name", edited_item_text)
		else:
			if edited_item_text.is_empty():
				edited_type_text = NEW_TYPE_TEXT

			edited_item_text = edited_type_text
			switchboard[edited_item_parent_text][edited_item.get_index()].set("type", edited_item_text)

	edited_type_text = ""
	edited_item.set_text(edited_column, edited_item_text)
	switchboard_changed.emit(switchboard)


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
	var param_text: String

	if item_parent == get_root():
		channel_text = _make_unique(NEW_METHOD_TEXT, switchboard.keys())
		param_text = "args: 0"
		switchboard.set(channel_text, [])
		_create_item_adder(new_item, ADD_PARAM_TEXT, ADD_PARAM_COLOR)
	else:
		var item_parent_text: String = item_parent.get_text(FIRST_COLUMN)
		channel_text = _make_unique(NEW_PARAM_TEXT, switchboard[item_parent_text].map(func(x): return x.name))
		param_text = NEW_TYPE_TEXT
		switchboard[item_parent_text].append({"name": channel_text, "type": param_text})
		_inc_arg_count(item_parent)

	new_item.collapsed = true
	new_item.set_text(FIRST_COLUMN, channel_text)
	new_item.set_text(SECOND_COLUMN, param_text)
	new_item.add_button(SECOND_COLUMN, remove_item_icon)

	switchboard_changed.emit(switchboard)


func _create_item_adder(adder_parent: TreeItem, adder_text: String, adder_bg_color: Color) -> void:
	if is_locked:
		return

	var new_item_adder: TreeItem = create_item(adder_parent)
	new_item_adder.set_icon(FIRST_COLUMN, add_item_icon)
	new_item_adder.set_text(FIRST_COLUMN, adder_text)
	new_item_adder.set_custom_bg_color(FIRST_COLUMN, adder_bg_color)
	new_item_adder.set_custom_bg_color(SECOND_COLUMN, adder_bg_color)
	new_item_adder.set_selectable(SECOND_COLUMN, false)


func _inc_arg_count(method_item: TreeItem) -> void:
	_update_arg_count(method_item, 1)


func _dec_arg_count(method_item) -> void:
	_update_arg_count(method_item, -1)


func _update_arg_count(method_item: TreeItem, adjustment: int) -> void:
	var arg_text: String = method_item.get_text(SECOND_COLUMN).to_snake_case()
	var arg_int: int = arg_text.trim_prefix("args: ").to_int()
	arg_int += adjustment
	var new_arg_text: String = "args: %d" % arg_int
	method_item.set_text(SECOND_COLUMN, new_arg_text)
