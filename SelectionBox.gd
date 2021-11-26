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
export(int, LAYERS_3D_PHYSICS) var selection_collision_mask = 0

onready var camera = get_parent().get_node("Camera")
onready var direct_space_state: PhysicsDirectSpaceState = get_tree().get_nodes_in_group("surface")[0].get_world().direct_space_state

func _ready():
	pass

func _unhandled_input(event):
	if Globals.cursor_state == Globals.CursorState.Select:
		if event.is_action_pressed("left_click"):
			visible = true
			selection_box.point1 = get_viewport().get_mouse_position()
		if event.is_action_released("left_click"):
			visible = false
			#TODO this needs to be cleaned up
			var num_selected = get_tree().get_nodes_in_group("surface")[0].select_units(get_rect(), get_tree().get_nodes_in_group("surface")[0].player_team)
			if num_selected < 1:
				var ray_origin = camera.project_ray_origin(get_viewport().get_mouse_position())
				var ray_normal = camera.project_ray_normal(get_viewport().get_mouse_position())
				var raycast_result = direct_space_state.intersect_ray(ray_origin, ray_origin + ray_normal * 1e6, [], selection_collision_mask, true, true)
				if not raycast_result.empty() and "IS_UNIT" in raycast_result.collider.get_parent():
					var unit: Unit = raycast_result.collider.get_parent()
					if unit in get_tree().get_nodes_in_group("surface")[0].player_team.units:
						if Input.is_action_pressed("queue"):
							unit.is_selected = !unit.is_selected
						else:
							unit.is_selected = true 


	if Input.is_action_pressed("left_click"):
		selection_box.point2 = get_viewport().get_mouse_position()
		rect_size = selection_box.get_rect().size
		rect_position = selection_box.get_rect().position
