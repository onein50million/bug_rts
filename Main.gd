extends Spatial

export var surface_path: NodePath
onready var surface = get_node(surface_path)

export var camera_path: NodePath
onready var camera = get_node(camera_path)

export var selection_box_path: NodePath
onready var selection_box = get_node(selection_box_path)

onready var direct_space_state = get_world().direct_space_state


func _unhandled_input(event):
	if event.is_action_pressed("deselect"):
		if Globals.cursor_state == Globals.CursorState.Select:
			for unit in surface.player_team.units:
				unit.is_selected = false
		else:
			Globals.cursor_state = Globals.CursorState.Select
	
	match Globals.cursor_state:
		Globals.CursorState.Select:
			pass #handled in Person.gd and SelectionBox.gd, for a !!!FUN!!! project try moving it all in here
		Globals.CursorState.Attack:
			if event.is_action_pressed("left_click"):
				var ray_origin = camera.project_ray_origin(get_viewport().get_mouse_position())
				var ray_normal = camera.project_ray_normal(get_viewport().get_mouse_position())
				var raycast_result = direct_space_state.intersect_ray(ray_origin, ray_origin + ray_normal * 1e6, [], 0b100, true, true)
				if not raycast_result.empty() and "IS_UNIT" in raycast_result.collider.get_parent():
					var target_unit: Unit = raycast_result.collider.get_parent()
					for unit in surface.player_team.units:
						if unit.is_selected and unit.team != target_unit.team:
							if not Input.is_action_pressed("queue"):
								unit.clear_orders()
							var new_order = Globals.Order.new(Globals.OrderType.AttackUnit, surface)
							new_order.data.target = target_unit
							new_order.update_order()
							unit.new_orders(new_order)
				elif raycast_result.empty():
					print("attack move unimplemented")

func _process(_delta):
	var alive_team_count = 0
	var last_alive_team
	for team in surface.teams:
		if is_instance_valid(team.queen):
			alive_team_count += 1
			last_alive_team = team
	if alive_team_count == 1:
		celebrate(last_alive_team)
	if alive_team_count  <= 0:
		tie()
func celebrate(winner: Globals.Team):
	$MainUI/WinnerDialog.dialog_text = "Winner is %s" % winner.team_name
	$MainUI/WinnerDialog.popup_centered()

func tie():
	$MainUI/WinnerDialog.dialog_text = "Tie, no winner"
	$MainUI/WinnerDialog.popup_centered()
