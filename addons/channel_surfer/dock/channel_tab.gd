@tool
extends HBoxContainer


# const FORWARD_TEXT: String = ">"
# const BACKWARD_TEXT: String = "<"


@onready var channel_tree: Tree = %ChannelTree
@onready var switchboard: Control = %Switchboard
@onready var back_forth_button: Button = %BackForthButton

@onready var forward_icon = get_theme_icon("Forward", &"EditorIcons")
@onready var backward_icon = get_theme_icon("Back", &"EditorIcons")


func _ready() -> void:
    switchboard.hide()
    channel_tree.show()

    back_forth_button.icon = forward_icon
    back_forth_button.pressed.connect(_on_back_forth_button_pressed)


func _on_back_forth_button_pressed() -> void:
    if channel_tree.visible:
        channel_tree.hide()
        back_forth_button.icon = backward_icon
        switchboard.show()
    else:
        switchboard.hide()
        back_forth_button.icon = forward_icon
        channel_tree.show()