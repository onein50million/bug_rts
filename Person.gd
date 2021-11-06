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

var units = []


func fmod(x, y):
	return x - y * floor(x / y)

func get_face_position(face_index):
	var sum = Vector3.ZERO
	
	for i in range(3):
		sum += mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index, i))
	
	return sum / 3.0 

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
	
func is_inside_triangle(point: Vector3, face_index: int):
	#https://math.stackexchange.com/a/544947
	#barycentric coordinates
	#TODO: make better variable names
	
	var normal = mesh_tool.get_face_normal(face_index)
	
	var p1 = mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index,0))
	var p2 = mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index,1))
	var p3 = mesh_tool.get_vertex(mesh_tool.get_face_vertex(face_index,2))
	
	var plane = Plane(p1,p2,p3)
#	var plane_projected_point = point - (normal * plane.distance_to(point))
	var plane_projected_point = plane.project(point)
	var u = p2 - p1
	var v = p3 - p1
	var n = u.cross(v)
	var w = plane_projected_point - p1
	
	var gamma = (u.cross(w).dot(n)) / (n.dot(n))
	var beta = (w.cross(v).dot(n)) / (n.dot(n))
	var alpha = 1 - gamma - beta
	
	var epsilon = 0.0
#	var above_triangle = (point - p1).dot((p2-p1).cross(p3-p1)) > 0.0
#	var above_triangle = point.dot(point - get_face_position(face_index)) > 0.
	var below_plane = normal.dot(point) - plane.d < -0.1
#	if above_triangle < 0.0:
#		print(above_triangle)
	var output = not below_plane and -epsilon <= alpha and alpha <= 1.0 + epsilon  and -epsilon <= beta and beta <= 1.0 + epsilon and -epsilon <= gamma and gamma <= 1.0 + epsilon
	return output
	
func get_closest_face_data(position: Vector3) -> FaceData:
	var closest_position = get_face_position(0)
	var closest_distance = closest_position.distance_to(position)
	var closest_index = 0
	var distance_limit = 1.0
	for face_index in range(mesh_tool.get_face_count()):
		var face_position = get_face_position(face_index)
		var face_distance = face_position.distance_to(position)
		
		if is_inside_triangle(position, face_index):
#			print("found triangle!")
			closest_position = face_position
			closest_distance = face_distance
			closest_index = face_index
			return FaceData.new(closest_index, closest_position)
	print("Failed to find triangle")
	return FaceData.new(0, Vector3.ZERO) #shouldn't reach


func select_units(selection_box: Rect2):
	for unit in units:
		var viewport_position = camera.unproject_position(unit.transform.origin)
		unit.is_selected = selection_box.has_point(viewport_position)


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
	for i in range(5):
		var new_unit = bug_scene.instance()
		new_unit.transform.origin = Vector3(rand_range(-spread, spread),rand_range(-spread, spread),rand_range(-spread, spread))
		
		get_parent().call_deferred("add_child",new_unit)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta

