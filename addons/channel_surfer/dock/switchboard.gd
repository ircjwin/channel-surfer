@tool
class_name Switchboard
extends Panel


@onready var root_button: Button = %RootButton
@onready var main_hbox_container: HBoxContainer = %MainHBoxContainer
@onready var main_button: Button = %MainButton
@onready var main_option_button: OptionButton = %MainOptionButton
@onready var sub_hbox_container: HBoxContainer = %SubHBoxContainer
@onready var sub_button: Button = %SubButton
@onready var sub_option_button: OptionButton = %SubOptionButton
@onready var main_texture_rect: TextureRect = %MainTextureRect
@onready var sub_texture_rect: TextureRect = %SubTextureRect

const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const SWITCH_DIR: String = CS_PATHS.SWITCH_DIR

const SCRIPT_NAME = "SCRIPT_NAME"
const FUNC_COMMENT = "FUNC_COMMENT"
const FUNC_NAME = "FUNC_NAME"
const FUNC_PARAMS = "FUNC_PARAMS"
const FUNC_ARGS = "FUNC_ARGS"

const HEADER_TEMPLATE = (
    "extends Resource\n" +
    "\n" +
    "\n" +
    "signal switch_flipped(channel_switch: String, method_switch: String, param_switches: Array)\n" +
    "\n" +
    "var channel_name = \"" + SCRIPT_NAME + "\"\n"
)

const COMMENT_TEMPLATE = (
    "\n" +
    "\n" +
    "## " + FUNC_COMMENT + "\n"
)

const FUNC_TEMPLATE = (
    "func " + FUNC_NAME + "(" + FUNC_PARAMS + ") -> void:\n" +
    "	switch_flipped.emit(channel_name, " + FUNC_NAME + ", [" + FUNC_ARGS + "])\n"
)

var channel_map: Dictionary


func _ready() -> void:
    main_texture_rect.texture = get_theme_icon("Forward", &"EditorIcons")
    sub_texture_rect.texture = get_theme_icon("Forward", &"EditorIcons")
    sub_texture_rect.hide()

    sub_button.hide()
    sub_option_button.hide()
    main_button.hide()
    main_option_button.show()

    root_button.pressed.connect(_on_root_button_pressed)
    main_button.pressed.connect(_on_main_button_pressed)
    sub_button.pressed.connect(_on_sub_button_pressed)
    main_option_button.item_selected.connect(_on_main_option_button_item_selected)
    sub_option_button.item_selected.connect(_on_sub_option_button_item_selected)


func _build_script(channel_name: String) -> void:
    var script_text = (
        HEADER_TEMPLATE.replace(SCRIPT_NAME, channel_name) +
        COMMENT_TEMPLATE.replace(FUNC_COMMENT, "This method returns armor price.") +
        FUNC_TEMPLATE.replace(FUNC_NAME, "get_price").replace(FUNC_PARAMS, "").replace(FUNC_ARGS, "") +
        COMMENT_TEMPLATE.replace(FUNC_COMMENT, "This method sets armor price.") +
        FUNC_TEMPLATE.replace(FUNC_NAME, "set_price").replace(FUNC_PARAMS, "new_price: int").replace(FUNC_ARGS, "new_price")
    )
    var file: FileAccess = FileAccess.open(SWITCH_DIR + channel_name + ".gd", FileAccess.WRITE)
    file.store_string(script_text)
    file.close()


func fill_options(new_options: Dictionary) -> void:
    channel_map = new_options
    _fill_main_options()
    _fill_sub_options()


func fill_switches(new_switches: Dictionary) -> void:
    pass


func _fill_main_options() -> void:
    main_option_button.clear()
    main_option_button.add_item("...")
    main_option_button.select(0)

    for main_option: String in channel_map.keys():
        main_option_button.add_item(main_option.capitalize())


func _fill_sub_options() -> void:
    sub_option_button.clear()
    sub_option_button.add_item("...")
    sub_option_button.select(0)

    var main_selection = main_option_button.selected
    if main_selection == 0:
        return

    var main_option = main_option_button.get_item_text(main_selection).to_snake_case()
    for sub_option: String in channel_map[main_option]:
        sub_option_button.add_item(sub_option.capitalize())


func _on_root_button_pressed() -> void:
    # Item Selected signal likely doesn't fire when item selected with code
    # Need to verify that button text, option button selection, and tooltips reset/update
    main_button.hide()
    main_option_button.show()
    main_option_button.select(0)
    main_button.text = main_option_button.get_item_text(0)

    sub_texture_rect.hide()
    sub_button.hide()
    sub_option_button.hide()
    sub_option_button.select(0)
    sub_button.text = sub_option_button.get_item_text(0)


func _on_main_button_pressed() -> void:
    sub_option_button.hide()
    sub_button.show()

    main_button.hide()
    main_option_button.show()


func _on_sub_button_pressed() -> void:
    main_option_button.hide()
    main_button.show()

    sub_button.hide()
    sub_option_button.show()


func _on_main_option_button_item_selected(index: int) -> void:
    # Make separate method for instances where select signal isn't emitted
    if index == 0:
        main_button.text = main_option_button.get_item_text(index)
        main_button.tooltip_text = ""
        main_option_button.tooltip_text = ""
        sub_texture_rect.hide()
        sub_button.hide()
        sub_option_button.hide()
        _fill_sub_options()
        return

    main_option_button.hide()
    main_option_button.tooltip_text = main_option_button.get_item_text(index)
    main_button.text = main_option_button.get_item_text(index)
    main_button.tooltip_text = main_option_button.get_item_text(index)
    main_button.show()
    _fill_sub_options()
    sub_button.hide()
    sub_texture_rect.show()
    sub_option_button.show()


func _on_sub_option_button_item_selected(index: int) -> void:
    # Make separate method for instances where select signal isn't emitted
    if index == 0:
        sub_button.text = sub_option_button.get_item_text(index)
        sub_button.tooltip_text = ""
        sub_option_button.tooltip_text = ""
        return

    sub_button.tooltip_text = sub_option_button.get_item_text(index)
    sub_button.text = sub_option_button.get_item_text(index)
    sub_option_button.tooltip_text = sub_option_button.get_item_text(index)
