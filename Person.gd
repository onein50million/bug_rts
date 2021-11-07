extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var time = 0.0

var cooldown = 0.0

onready var bug_scene = preload("res://bug.tscn")

export var camera_path: NodePath
export var ball_path: NodePath

var camera: Camera


var astar: AStar

var surface_tool: SurfaceTool
var mesh_tool: MeshDataTool

onready var physics_space_state = get_world().direct_space_state

onready var face_helper = preload("res://dll/BugRtsLib.gdns").new()

var units = []


func fmod(x, y):
	return x - y * floor(x / y)

func get_face_tangent(face_index):
	var first = mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index, 0))
	var second = mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index, 1))
	return (first - second).normalized()
	
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
	
func get_closest_face_data(position: Vector3) -> FaceData:
	return face_helper.get_closest_face_data(position, mesh_tool)

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
	
#	var edges = [
#		mesh_tool.get_face_edge(face_index, 0),
#		mesh_tool.get_face_edge(face_index, 1),
#		mesh_tool.get_face_edge(face_index, 2)
#	]
#
#	var output: PoolIntArray = []
#	var test = []
#	for edge_index in edges:
#		print(mesh_tool.get_edge_faces(edge_index))
#		for connected_faces_index in mesh_tool.get_edge_faces(edge_index):
#			test.append(connected_faces_index)
#			if connected_faces_index != face_index:
#				output.append(connected_faces_index)
#	print(test)
#	return output


func select_units(selection_box: Rect2):
	#TODO: don't select occluded units
	#TODO: hold shift to add selection
	for unit in units:
		var viewport_position = camera.unproject_position(unit.transform.origin)
		unit.is_selected = selection_box.has_point(viewport_position)

func _input(event):
	if event.is_action_released("move"):
		var ray_origin = camera.project_ray_origin(get_viewport().get_mouse_position())
		var ray_normal = camera.project_ray_normal(get_viewport().get_mouse_position())

		var raycast_result = physics_space_state.intersect_ray(ray_origin,ray_origin + ray_normal * 1e6)
		if raycast_result.empty():
			print("no hits")
			return
		
		for unit in units:
			if unit.is_selected:
#				var random_vector = Vector3(rand_range(-spread,spread),rand_range(-spread,spread),rand_range(-spread,spread))
#				var target = raycast_result.position + random_vector
				if not Input.is_action_pressed("queue"):
					unit.clear_orders()
				var starting_point = astar.get_closest_point(unit.transform.origin)
				var ending_point = astar.get_closest_point(raycast_result.position)
				var point_path = astar.get_point_path(starting_point, ending_point)
				
				if point_path.size() > 1:
					point_path.remove(0) #skip the first node
				if point_path.size() > 1:
					point_path.remove(point_path.size() - 1) #and the last node
				
				for point in point_path:
					var new_order = Unit.Order.new(Unit.OrderType.Move,self)
					new_order.data.target = point
					new_order.update_order()
					unit.new_orders(new_order)
				var target = raycast_result.position
				var new_order = Unit.Order.new(Unit.OrderType.Move, self)
				new_order.data.target = target
				new_order.update_order()
				unit.new_orders(new_order)
			
# Called when the node enters the scene tree for the first time.
func _ready():
	print("Creating mesh tool")
	$CollisionShape.shape = $MeshInstance.mesh.create_trimesh_shape()
	camera = get_node(camera_path)
	
	surface_tool = SurfaceTool.new()
	surface_tool.create_from($MeshInstance.mesh,0)
	
	var array_plane = surface_tool.commit()
	mesh_tool = MeshDataTool.new()
	mesh_tool.create_from_surface(array_plane,0)
	
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
	
	print("Spawning test bugs")
	units.append(get_parent().get_node("bug"))
	var spread = 100.0
	for i in range(100):
		var new_unit = bug_scene.instance()
		new_unit.transform.origin = Vector3(rand_range(-spread, spread),rand_range(-spread, spread),rand_range(-spread, spread))
		units.append(new_unit)
		get_parent().call_deferred("add_child",new_unit)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta

