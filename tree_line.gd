extends LineEdit


func _gui_input(event: InputEvent) -> void:
    if event.is_action("ui_text_caret_up") or event.is_action("ui_text_caret_down"):
        accept_event()