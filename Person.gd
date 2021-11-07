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

func select_units(selection_box: Rect2):
	#TODO: don't select occluded units
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
				var target = raycast_result.position
				var new_order = Unit.Order.new(Unit.OrderType.Move, self)
				new_order.data.target = target
				new_order.update_order()
				unit.new_orders(new_order, not Input.is_action_pressed("queue"))
			
# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape.shape = $MeshInstance.mesh.create_trimesh_shape()
	camera = get_node(camera_path)
	
	surface_tool = SurfaceTool.new()
	surface_tool.create_from($MeshInstance.mesh,0)
	
	var array_plane = surface_tool.commit()
	mesh_tool = MeshDataTool.new()
	mesh_tool.create_from_surface(array_plane,0)
	
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

