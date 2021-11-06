extends ColorRect

class Box:
	var point1: Vector2
	var point2: Vector2
	
	func _init():
		point1 = Vector2.ZERO
		point2 = Vector2.ZERO
	func get_rect():
		var upperleft = Vector2.ZERO
		var lowerright = Vector2.ZERO
		if point1.x < point2.x:
			upperleft.x = point1.x
			lowerright.x = point2.x
		else:
			upperleft.x = point2.x
			lowerright.x = point1.x
		if point1.y < point2.y:
			upperleft.y = point1.y
			lowerright.y = point2.y
		else:
			upperleft.y = point2.y
			lowerright.y = point1.y
		
		return Rect2(upperleft, lowerright - upperleft)
		
var selection_box: Box = Box.new()

func _ready():
	pass

func _input(event):
	if event.is_action_pressed("select"):
		visible = true
		selection_box.point1 = get_viewport().get_mouse_position()
	if event.is_action_released("select"):
		visible = false
		get_parent().get_node("Person").select_units(get_rect())
		

func _process(delta):
	if Input.is_action_pressed("select"):
		selection_box.point2 = get_viewport().get_mouse_position()
		rect_size = selection_box.get_rect().size
		rect_position = selection_box.get_rect().position
