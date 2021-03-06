extends RigidBody

class_name Surface

#TODO: Move a bunch of stuff out of here and into "Main" node

var time = 0.0

var cooldown = 0.0

onready var bug_scene = preload("res://Units/bug.tscn")
onready var queen_scene = preload("res://Units/bug_queen.tscn")
onready var hematoph_scene = preload("res://Units/Buildings/Economy/Hematoph/Hematoph.tscn")
onready var enzyme_scene = preload("res://Units/Buildings/Economy/EnzymeGland/EnzymeGland.tscn")

export var camera_path: NodePath

var camera: Camera

var astar: AStar

var surface_tool: SurfaceTool
var mesh_tool: MeshDataTool

onready var physics_space_state = get_world().direct_space_state

onready var face_helper = preload("res://dll/BugRtsLib.gdns").new()

var teams = []
var player_team: Globals.Team

func fmod(x, y):
	return x - y * floor(x / y)

func get_face_tangent(face_index):
	var first = mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index, 0))
	var second = mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index, 1))
	return (first - second).normalized()

func get_closest_face(position: Vector3) -> FaceData:
	return face_helper.get_closest_face(position, mesh_tool)

class FaceData:
	var index: int
	var position: Vector3
	
	func _init(_index:int, _position: Vector3):
		self.index = _index
		self.position = _position
	
	
func project_point(face_index: int, point: Vector3) -> Vector3:
	var p1 = mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index,0))
	var p2 = mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index,1))
	var p3 = mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index,2))

	var plane = Plane(p1,p2,p3)
	return plane.project(point)

func is_inside_triangle(point: Vector3, face_index: int):
	#https://math.stackexchange.com/a/544947
	#barycentric coordinates
	#TODO: make better variable names
	return face_helper.is_inside_triangle(point, face_index, mesh_tool)
	
func get_standing_face(position: Vector3) -> FaceData:
	return face_helper.get_standing_face(position, mesh_tool)

func get_face_position(face_index):
	return face_helper.get_face_position(face_index, mesh_tool)

func get_connected_faces(face_index: int) -> PoolIntArray:
	var output: PoolIntArray = []
	var main_face_vertices = [
		mesh_tool.get_face_vertex(face_index, 0),
		mesh_tool.get_face_vertex(face_index, 1),
		mesh_tool.get_face_vertex(face_index, 2)
	]
	for face in mesh_tool.get_face_count():
		if face != face_index:
			var face_vertices = [
				mesh_tool.get_face_vertex(face, 0),
				mesh_tool.get_face_vertex(face, 1),
				mesh_tool.get_face_vertex(face, 2)
			]
			for vertex in face_vertices:
				for main_vertex in main_face_vertices:
					if mesh_tool.get_vertex(vertex).distance_squared_to(mesh_tool.get_vertex(main_vertex)) < 0.001:
						output.append(face)
	return output

#func add_order(order: Unit.Order, team: Team):
#	for unit in team.units:
#		unit.new_orders(order)

func clear_selection(team:Globals.Team):
	for unit in team.units:
		unit.is_selected = false

func select_closest_unit(mouse_position, team: Globals.Team):
	var threshold_distance = 5*5
	var closest_unit
	var closest_distance = INF
	for unit in team.units:
		var viewport_position = camera.unproject_position(unit.transform.origin)
		var distance = viewport_position.distance_squared_to(mouse_position)
		if distance < closest_distance and distance < threshold_distance:
			closest_distance = distance
			closest_unit = unit
	if closest_unit:
		closest_unit.is_selected = true
	elif not Input.is_action_pressed("queue"):
		clear_selection(team)


func select_units(selection_box: Rect2, team: Globals.Team) -> int:
	var num_selected: int = 0
	for unit in team.units:
		var viewport_position = camera.unproject_position(unit.transform.origin)
		if not Input.is_action_pressed("queue"):
			unit.is_selected = false
		if selection_box.has_point(viewport_position):
			var ray_cast_result = physics_space_state.intersect_ray(
				camera.project_ray_origin(viewport_position) ,
#				unit.transform.origin + unit.transform.basis.y*0.005,
				unit.transform.origin,
				[],
				0b11,
				true,
				true)
			unit.is_selected = unit.is_selected or not ray_cast_result.empty() and "IS_UNIT" in ray_cast_result.collider.get_parent()
			num_selected += int(unit.is_selected)
	return num_selected

func spawn_bug(bug_transform: Transform,type,team:Globals.Team, ghost = null):
	var new_unit = Globals.unit_scenes[type].instance()
	if type == Globals.UnitType.Queen:
		team.queen = new_unit
	if is_instance_valid(ghost):
		ghost.queue_free()
	new_unit.transform = bug_transform
	new_unit.current_face = get_closest_face(bug_transform.origin).index
	new_unit.team = team
	new_unit.camera = camera
	team.units.append(new_unit)
	get_parent().call_deferred("add_child",new_unit)
#	get_parent().add_child(new_unit)

func _unhandled_input(event):
	if Globals.cursor_state == Globals.CursorState.Select:
		if event.is_action_released("right_click"):
			var ray_origin = camera.project_ray_origin(get_viewport().get_mouse_position())
			var ray_normal = camera.project_ray_normal(get_viewport().get_mouse_position())

			var raycast_result = physics_space_state.intersect_ray(
				ray_origin,
				ray_origin + ray_normal * 1e6,
				[],0xFFFFFFFF,
				true,
				true
				)
			if raycast_result.empty():
				print("no hits")
				return
			if "IS_UNIT" in raycast_result.collider.get_parent(): 
				var target = raycast_result.collider.get_parent() #This is a little fragile, TODO: Make this more robust
				for unit in player_team.units:
					if unit.is_selected:
						if not Input.is_action_pressed("queue"):
							unit.clear_orders()
						var new_order_type = unit.friendly_contextual_order if unit.team == target.team else unit.enemy_contextual_order
						var new_order = Globals.Order.new(new_order_type, self)
						match new_order_type:
							Globals.OrderType.AttackUnit:
								new_order.data.target = target
							Globals.OrderType.Move:
								new_order.data.target = target.transform.origin
						new_order.update_order()
						unit.new_orders(new_order)
			else:
				for unit in player_team.units:
					if unit.is_selected:
						if not Input.is_action_pressed("queue"):
							unit.clear_orders()
		#				var random_vector = Vector3(rand_range(-spread,spread),rand_range(-spread,spread),rand_range(-spread,spread))
		#				var target = raycast_result.position + random_vector
						
						var target = raycast_result.position
						var new_order = Globals.Order.new(Globals.OrderType.Move, self)
						new_order.data.target = target
						new_order.update_order()
						unit.new_orders(new_order)

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Creating mesh tool")
	$CollisionShape.shape = $person/Armature/Skeleton/Mesh.mesh.create_trimesh_shape()
	camera = get_node(camera_path)
	
	surface_tool = SurfaceTool.new()
	surface_tool.create_from($person/Armature/Skeleton/Mesh.mesh,0)
	
	var array_plane = surface_tool.commit()
	mesh_tool = MeshDataTool.new()
	print("Mesh Tool Result: %s: " % mesh_tool.create_from_surface(array_plane,0))
	
	print("Creating AStar nav tree")
	
	#TODO cache this because it kinda takes a while
	astar = AStar.new()
	for face_index in mesh_tool.get_face_count():
		astar.add_point(face_index, get_face_position(face_index))
	print("Finished adding points, now connecting them")
	for point in astar.get_points():
		var connected_faces = get_connected_faces(point)
		for connected_face in connected_faces:
			astar.connect_points(point, connected_face)
	
	player_team = Globals.Team.new()
	teams.append(player_team)
	player_team.color = Globals.player_team_color
	player_team.team_name = Globals.player_team_name
	player_team.starting_face = get_closest_face(Globals.player_starting_position).index
	Globals.player_team = player_team
	
	for _team in range(Globals.enemy_team_count):
		var new_team = Globals.Team.new()
		new_team.starting_face = randi() % mesh_tool.get_face_count()
		new_team.ai = Globals.AI.new(new_team)
		teams.append(new_team)
	for team in teams:
		if team == player_team and Globals.spectate:
			continue
		spawn_bug(Transform(Basis.IDENTITY,get_face_position(team.starting_face)),Globals.UnitType.Queen,team)

	var root = get_parent().get_node("MainUI/TeamList").create_item()
	root.set_text(0, "Name")
	root.set_text(1, "Color")
	root.set_text(2, "Queen Health")
	root.set_text(3, "Bug Kills")
	root.set_text(4, "Queen Kills")

	for team in teams:
		get_parent().get_node("MainUI/TeamList").new_item(team)
	
	var order_icon_scene = preload("res://UI/OrderIcon.tscn")
#	get_parent().get_node("MainUI/Orders").margin_right = 64 * Globals.CursorState.size()
#	get_parent().get_node("MainUI/Orders").margin_top = -64
	for y in range(3):
		for x in range(4):
			var new_order_icon:Button = order_icon_scene.instance()
			if x+4*y < Globals.CursorState.size():
				var state = Globals.CursorState.values()[x+4*y]
				if state in [Globals.CursorState.Select, Globals.CursorState.Attack]:
					new_order_icon.cursor_state = state
					new_order_icon.text = Globals.CursorState.keys()[state]
			elif x == 0 and  y == 2:
				new_order_icon.text = "Same Type"
				new_order_icon.command = "same_type_select"
			else:
#				new_order_icon.cursor_state = Globals.CursorState.Move
				new_order_icon.text = ""
			var shortcut = ShortCut.new()
			var action = InputEventAction.new()
			action.action = "grid%d%d"%[x,y]
			shortcut.shortcut = action
			new_order_icon.shortcut = shortcut
			get_parent().get_node("MainUI/TabContainer/Orders").add_child(new_order_icon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta

