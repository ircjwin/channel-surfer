@tool
extends FoldableContainer


@onready var param_v_box: VBoxContainer = %ParamVBox
@onready var new_param_button: Button = %NewParamButton
@onready var param_switch_scene: PackedScene = preload("res://addons/channel_surfer/dock/param_switch.tscn")

@onready var tree_arrow = get_theme_icon("arrow", &"Tree")
@onready var tree_arrow_collapsed = get_theme_icon("arrow_collapsed", &"Tree")
@onready var tree_panel = get_theme_stylebox("panel", &"Tree")
@onready var tree_focus = get_theme_stylebox("focus", &"Tree")
@onready var tree_selected = get_theme_stylebox("selected", &"Tree")
@onready var tree_hovered = get_theme_stylebox("hovered", &"Tree")

var delete_method_button: Button


func _ready() -> void:
    add_theme_stylebox_override("panel", tree_panel)
    add_theme_stylebox_override("focus", tree_focus)
    add_theme_stylebox_override("title_panel", tree_panel)
    add_theme_stylebox_override("title_hover_panel", tree_hovered)
    add_theme_icon_override("expanded_arrow", tree_arrow)
    add_theme_icon_override("folded_arrow", tree_arrow_collapsed)

    _mount_delete_method_button()

    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    new_param_button.pressed.connect(_on_new_param_button_pressed)
    delete_method_button.pressed.connect(_on_delete_method_button_pressed)


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton \
    and event.button_index == MOUSE_BUTTON_LEFT \
    and event.double_click:
        pass


func _mount_delete_method_button() -> void:
    delete_method_button = Button.new()
    add_title_bar_control(delete_method_button)
    delete_method_button.icon = get_theme_icon("Remove", &"EditorIcons")
    # delete_method_button.hide()


func _on_mouse_entered() -> void:
    # delete_method_button.show()
    pass


func _on_mouse_exited() -> void:
    # if not Rect2(Vector2(), size).has_point(get_local_mouse_position()):
    #     delete_method_button.hide()
    pass


func _on_delete_method_button_pressed() -> void:
    queue_free()


func _on_new_param_button_pressed() -> void:
    var param_switch_instance: HBoxContainer = param_switch_scene.instantiate()
    param_v_box.add_child(param_switch_instance)
    param_v_box.move_child(param_switch_instance, -2)
    param_switch_instance.build_switch()
