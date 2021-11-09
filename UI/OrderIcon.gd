extends Button

var cursor_state

#func _input(event):
#	get_tree().set_input_as_handled()

func _process(_delta):
	pressed = cursor_state == Globals.cursor_state

func _on_OrderIcon_toggled(_button_pressed):
	Globals.cursor_state = cursor_state
