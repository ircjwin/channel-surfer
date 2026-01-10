@tool
extends HBoxContainer


const FORWARD_TEXT: String = ">"
const BACKWARD_TEXT: String = "<"


@onready var channel_tree: Tree = %ChannelTree
@onready var switchboard: Control = %Switchboard
@onready var back_forth_button: Button = %BackForthButton


func _ready() -> void:
    switchboard.hide()
    channel_tree.show()

    back_forth_button.text = FORWARD_TEXT
    back_forth_button.pressed.connect(_on_back_forth_button_pressed)


func _on_back_forth_button_pressed() -> void:
    if channel_tree.visible:
        channel_tree.hide()
        back_forth_button.text = BACKWARD_TEXT
        switchboard.show()
    else:
        switchboard.hide()
        back_forth_button.text = FORWARD_TEXT
        channel_tree.show()