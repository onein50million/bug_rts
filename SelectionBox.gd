extends ColorRect



func _ready():
	pass

func _input(event):
	if event.is_action_pressed("select"):
		visible = true
		rect_position = get_viewport().get_mouse_position()
	if event.is_action_released("select"):
		visible = false
		get_parent().get_node("Person").select_units(get_rect())
		

func _process(delta):
	if Input.is_action_pressed("select"):
		rect_size = get_viewport().get_mouse_position() -  rect_position
