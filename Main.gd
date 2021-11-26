extends Spatial

export var surface_path: NodePath
onready var surface = get_node(surface_path)

export var camera_path: NodePath
onready var camera = get_node(camera_path)

export var selection_box_path: NodePath
onready var selection_box = get_node(selection_box_path)

onready var direct_space_state = get_world().direct_space_state

var can_place = false

var celebrated = false

func same_type_select():
	var selected_types = []
	for unit in surface.player_team.units:
		if unit.is_selected and not unit.unit_type in selected_types:
			selected_types.append(unit.unit_type)
	for unit in surface.player_team.units:
		if unit.unit_type in selected_types:
			unit.is_selected = true


func _unhandled_input(event):
	if event.is_action_released("build_mode"):
		Globals.cursor_state = Globals.CursorState.Build
	if event.is_action_pressed("deselect"):
		if Globals.cursor_state == Globals.CursorState.Build and is_instance_valid(Globals.build_ghost):
			Globals.build_ghost.queue_free()
			Globals.build_ghost = null
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
						if unit.is_selected:
							if not Input.is_action_pressed("queue"):
								unit.clear_orders()
							if unit.team == target_unit.team:
								unit.friendly_fire_enabled = true
							var new_order = Globals.Order.new(Globals.OrderType.AttackUnit, surface)
							new_order.data.target = target_unit
							new_order.update_order()
							unit.new_orders(new_order)
				elif raycast_result.empty():
					print("attack move unimplemented")
		Globals.CursorState.Build:
			if event.is_action_pressed("left_click"):
#				var ray_origin = camera.project_ray_origin(get_viewport().get_mouse_position())
#				var ray_normal = camera.project_ray_normal(get_viewport().get_mouse_position())
#				var raycast_result = direct_space_state.intersect_ray(ray_origin, ray_origin + ray_normal * 1e6, [], 0b1, true, true)
#				if not raycast_result.empty():
				if can_place:
					for unit in surface.player_team.units:
						if unit.is_selected and Globals.selected_build_unit in unit.buildable_units:
							if not Input.is_action_pressed("queue"):
								unit.clear_orders()
							var new_order = Globals.Order.new(Globals.OrderType.BuildUnit, surface)
							new_order.data.unit_type = Globals.selected_build_unit
							if Globals.unit_lookup[Globals.selected_build_unit].is_placed:
								new_order.data.position = Globals.build_ghost.transform.origin
								new_order.data.ghost = Globals.build_ghost.duplicate()
							new_order.update_order()
							unit.new_orders(new_order)
							if Globals.unit_lookup[Globals.selected_build_unit].is_placed:
								break
				

#func _init():
#	Globals.unit_scenes[Globals.UnitType.Bug] = preload("res://Units/bug.tscn")
#	Globals.unit_scenes[Globals.UnitType.Queen] = preload("res://Units/bug_queen.tscn")
#	Globals.unit_scenes[Globals.UnitType.Blood] = preload("res://Units/Buildings/Economy/Hematoph/Hematoph.tscn")
#	Globals.unit_scenes[Globals.UnitType.Enzyme] = preload("res://Units/Buildings/Economy/EnzymeGland/EnzymeGland.tscn")
#	Globals.unit_scenes[Globals.UnitType.Factory] = preload("res://Units/Buildings/Construction/bug_factory.tscn")

func _enter_tree():
	Globals.main_node = self
	for unit_type in Globals.UnitType.values():
		Globals.unit_lookup[unit_type] = Globals.unit_scenes[unit_type].instance()
	assert(Globals.unit_lookup.size() == Globals.UnitType.size())
func _process(delta):
#	print(Globals.player_team.blood)
#	print(Globals.player_team.queen.orders)
	var alive_team_count = 0
	var last_alive_team
	for team in surface.teams:
		if team.ai != null and is_instance_valid(team.queen):
			team.ai.process(delta)
		if is_instance_valid(team.queen):
			alive_team_count += 1
			last_alive_team = team
		
		var total_blood_wanted = 0.0
		var total_enzyme_wanted = 0.0
		for unit in team.units:
			if unit.orders.size() > 0:
				if unit.orders[0].type == Globals.OrderType.BuildUnit:
					total_blood_wanted += unit.blood_output
					total_enzyme_wanted += unit.enzyme_output
		var blood_ratio = min(1.0, team.blood / total_blood_wanted) if total_blood_wanted > 0.0 else 1.0
		var enzyme_ratio = min(1.0, team.enzymes / total_enzyme_wanted) if total_enzyme_wanted > 0.0 else 1.0
		for unit in team.units:
			if unit.orders.size() > 0:
				if unit.orders[0].type == Globals.OrderType.BuildUnit:
					unit.allocated_blood_ratio = blood_ratio
					unit.allocated_enzyme_ratio = enzyme_ratio

	if celebrated == false:
		if alive_team_count == 1:
			celebrate(last_alive_team)
		if alive_team_count <= 0:
			tie()
	
	if Globals.cursor_state == Globals.CursorState.Build and is_instance_valid(Globals.build_ghost):
		var ray_origin = camera.project_ray_origin(get_viewport().get_mouse_position())
		var ray_normal = camera.project_ray_normal(get_viewport().get_mouse_position())
		var raycast_result = direct_space_state.intersect_ray(ray_origin, ray_origin + ray_normal * 1e6, [Globals.build_ghost.get_node("GhostHitbox")], 0b1, true, true)
		if not raycast_result.empty():
			Globals.build_ghost.transform.origin = raycast_result.position
			Globals.build_ghost.transform.basis = Basis(Vector3.UP.cross(raycast_result.normal), raycast_result.normal, Vector3.UP).orthonormalized()
			
			can_place = Globals.build_ghost.get_node("GhostHitbox").get_overlapping_areas().size() < 1
			
			var material = SpatialMaterial.new()
			material.albedo_color = Color.green if can_place else Color.red
			Globals.build_ghost.get_node("Skeleton/Mesh").mesh.surface_set_material(0, material)


func celebrate(winner: Globals.Team):
	Engine.time_scale = 0.1
	celebrated = true
	$MainUI/WinnerDialog.dialog_text = "Winner is %s" % winner.team_name
	$MainUI/WinnerDialog.popup_centered()

func tie():
	Engine.time_scale = 0.1
	celebrated = true
	$MainUI/WinnerDialog.dialog_text = "Tie, no winner"
	$MainUI/WinnerDialog.popup_centered()

