extends Button

var cursor_state = null
var command = null
#func _input(event):
#	get_tree().set_input_as_handled()

func _ready():
	if command != null:
		group = null
		toggle_mode = false

func _process(_delta):
	if cursor_state != null:
		pressed = cursor_state == Globals.cursor_state

func _pressed():
	if cursor_state != null:
		Globals.cursor_state = cursor_state
	if command != null:
		get_node("/root/Main").call(command)
