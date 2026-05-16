@tool
extends VBoxContainer


signal switchboard_selected(name: String)

@onready var main_option_button: OptionButton = %MainOptionButton
@onready var switch_tree: SWITCH_TREE_TYPE = %SwitchTree

const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const SWITCH_TREE_TYPE: Resource = preload("res://addons/channel_surfer/dock/switch_tree.gd")
const SWITCH_DIR: String = CS_PATHS.SWITCH_DIR

var channel_map: Dictionary


func _ready() -> void:
    main_option_button.item_selected.connect(_on_main_option_button_item_selected)
    visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
    if not visible:
        switch_tree.switchboard = {}
        switch_tree.clear()
        main_option_button.select(0)


func fill_board(new_board: Dictionary) -> void:
    switch_tree.build_tree(new_board)


func fill_options(new_options: Dictionary) -> void:
    channel_map = new_options
    _fill_main_options()


func _fill_main_options() -> void:
    main_option_button.clear()
    main_option_button.add_item("...")
    main_option_button.select(0)

    for main_option: String in channel_map.keys():
        main_option_button.add_item(main_option.capitalize())


func _on_main_option_button_item_selected(index: int) -> void:
    # Make separate method for instances where select signal isn't emitted
    if index == 0:
        main_option_button.tooltip_text = ""
    else:
        main_option_button.tooltip_text = main_option_button.get_item_text(index)
        switchboard_selected.emit(main_option_button.get_item_text(index).to_snake_case())
