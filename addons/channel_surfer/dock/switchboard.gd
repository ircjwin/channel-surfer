@tool
class_name Switchboard
extends Panel


@onready var root_button: Button = %RootButton
@onready var main_hbox_container: HBoxContainer = %MainHBoxContainer
@onready var main_button: Button = %MainButton
@onready var main_option_button: OptionButton = %MainOptionButton
@onready var sub_hbox_container: HBoxContainer = %SubHBoxContainer
@onready var sub_arrow_label: Label = %SubArrowLabel
@onready var sub_button: Button = %SubButton
@onready var sub_option_button: OptionButton = %SubOptionButton


func _ready() -> void:
    sub_arrow_label.hide()
    sub_button.hide()
    sub_option_button.hide()
    main_button.hide()
    main_option_button.show()

    root_button.pressed.connect(_on_root_button_pressed)
    main_button.pressed.connect(_on_main_button_pressed)
    sub_button.pressed.connect(_on_sub_button_pressed)
    main_option_button.item_selected.connect(_on_main_option_button_item_selected)
    sub_option_button.item_selected.connect(_on_sub_option_button_item_selected)


func _enter_tree() -> void:
    if not is_node_ready():
        return

    main_option_button.add_item("...")
    main_option_button.add_item("A")
    main_option_button.add_item("B")
    main_option_button.add_item("C")

    sub_option_button.add_item("...")
    sub_option_button.add_item("1")
    sub_option_button.add_item("2")
    sub_option_button.add_item("3")


func _exit_tree() -> void:
    main_option_button.clear()
    sub_option_button.clear()


func _on_root_button_pressed() -> void:
    sub_arrow_label.hide()
    sub_button.hide()
    sub_option_button.hide()
    sub_option_button.select(0)

    main_button.hide()
    main_option_button.show()
    main_option_button.select(0)


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
    if index == 0:
        main_button.text = main_option_button.get_item_text(index)
        main_button.tooltip_text = ""
        main_option_button.tooltip_text = ""
        sub_arrow_label.hide()
        sub_button.hide()
        sub_option_button.hide()
        sub_option_button.select(0)
        return

    main_option_button.hide()
    main_option_button.tooltip_text = main_option_button.get_item_text(index)
    main_button.text = main_option_button.get_item_text(index)
    main_button.tooltip_text = main_option_button.get_item_text(index)
    main_button.show()
    sub_arrow_label.show()
    sub_option_button.show()


func _on_sub_option_button_item_selected(index: int) -> void:
    if index == 0:
        sub_button.text = sub_option_button.get_item_text(index)
        sub_button.tooltip_text = ""
        sub_option_button.tooltip_text = ""
        return

    sub_button.tooltip_text = sub_option_button.get_item_text(index)
    sub_button.text = sub_option_button.get_item_text(index)
    sub_option_button.tooltip_text = sub_option_button.get_item_text(index)
