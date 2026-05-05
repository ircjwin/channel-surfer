@tool
extends HBoxContainer


const CS_PATHS: Resource = preload("res://addons/channel_surfer/data/schema/cs_paths.gd")
const CHANNEL_TREE_TYPE: Resource = preload(CS_PATHS.TREE_TYPE)
const SWITCHBOARD_TYPE: Resource = preload(CS_PATHS.SWITCHBOARD_TYPE)

@onready var channel_tree: CHANNEL_TREE_TYPE = %ChannelTree
@onready var switchboard: SWITCHBOARD_TYPE = %Switchboard
@onready var back_forth_button: Button = %BackForthButton

#TODO: use unique %
@onready var channel_directory: VBoxContainer = %ChannelDirectory
@onready var forward_icon = get_theme_icon("Forward", &"EditorIcons")
@onready var backward_icon = get_theme_icon("Back", &"EditorIcons")


func _ready() -> void:
    switchboard.hide()
    channel_directory.show()

    back_forth_button.icon = forward_icon
    back_forth_button.pressed.connect(_on_back_forth_button_pressed)
    channel_tree.channel_rmb_selected.connect(_on_channel_tree_channel_rmb_selected)


func _on_channel_tree_channel_rmb_selected(_name: String) -> void:
    channel_directory.hide()
    switchboard.show()


func _on_back_forth_button_pressed() -> void:
    if channel_directory.visible:
        channel_directory.hide()
        back_forth_button.icon = backward_icon
        switchboard.show()
    else:
        switchboard.hide()
        back_forth_button.icon = forward_icon
        channel_directory.show()
