extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var time = 0.0

var cooldown = 0.0

var turn = 0.0

export var camera_path: NodePath
export var ball_path: NodePath

var camera: Camera
var ball: MeshInstance

var surface_tool: SurfaceTool
var mesh_tool: MeshDataTool

var tangent_space_position: Vector3 = Vector3.ZERO
var tangent_space_rotation: Quat = Quat(Vector3.FORWARD, 0.0)
var current_face = 0

var tangent_space_transform = Transform.IDENTITY

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

func quaternion_look_at(vector: Vector3, up: Vector3) -> Quat:
	var basis = Basis(vector.cross(up),up,vector)
	return basis.orthonormalized().get_rotation_quat().normalized()

#func quaternion_look_at(vector: Vector3) -> Quat:
#	var dot = Vector3.FORWARD.dot(vector)
#
#	var rot_angle =  acos(dot)
#	var rot_axis = Vector3.FORWARD.cross(vector).normalized()
#
#	return Quat(rot_axis, rot_angle)

# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape.shape = $MeshInstance.mesh.create_trimesh_shape()
	camera = get_node(camera_path)
	ball = get_node(ball_path)
	
	surface_tool = SurfaceTool.new()
	
	surface_tool.create_from($MeshInstance.mesh,0)
	
	var array_plane = surface_tool.commit()
	mesh_tool = MeshDataTool.new()
	mesh_tool.create_from_surface(array_plane,0)
	current_face = get_closest_face_data(ball.transform.origin).index
	update_tangent_transform()


func update_tangent_transform():
	var normal = mesh_tool.get_face_normal(current_face)
	var tangent = get_face_tangent(current_face)
	var bitangent = normal.cross(tangent)
	var basis = Basis(bitangent, normal, tangent).orthonormalized()
	tangent_space_transform = Transform(basis, get_face_position(current_face)).orthonormalized()

func transform_to_new_face():
	tangent_space_position = tangent_space_transform.inverse() * ball.transform.origin
	var new_rotation: Quat = (tangent_space_transform.inverse() * Transform(ball.transform.basis)).basis.get_rotation_quat()
	tangent_space_rotation = new_rotation

func set_ball_transform():
#	ball.transform = tangent_space_transform
	ball.transform.origin = tangent_space_transform * tangent_space_position
	ball.transform.basis = (tangent_space_transform * Transform(tangent_space_rotation)).basis

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
#
#	tangent_space_rotation *= Quat(Vector3(0.0,100.0*delta,0.0))

	
#	if time > 0.1:
#		time = 0.0
#		current_face = (current_face + 1) % mesh_tool.get_face_count()
#		update_tangent_transform()
#		transform_to_new_face()
#		set_ball_transform()

	#Tangent space transform * tangent space position = world position
#	var calculated_world_position = tangent_space_transform * tangent_space_position
#	tangent_space_position = tangent_space_transform.inverse() * (calculated_world_position + Vector3.UP * delta)
	var calculated_world_rotation = (tangent_space_transform * Transform(tangent_space_rotation)).basis
	
	turn = (int(Input.is_action_pressed("left")) - int(Input.is_action_pressed("right"))) * delta * 2.0
	
	var movement = (int(Input.is_action_pressed("forward")) - int(Input.is_action_pressed("reverse"))) * delta * 0.3
	tangent_space_rotation *= Quat(Vector3(0.0,turn,0.0))
#	print(tangent_space_rotation.xform(Vector3.FORWARD * movement * delta).length())
#	print(delta)
	tangent_space_position += tangent_space_rotation.xform(Vector3.FORWARD * movement)

	var calculated_world_position = tangent_space_transform * tangent_space_position
#	tangent_space_position = tangent_space_transform.inverse() * (calculated_world_position + Vector3.UP * delta)

	set_ball_transform()
	var closest_face_data = get_closest_face_data(ball.transform.origin)
	if current_face != closest_face_data.index:
		print("Face change")
		current_face = closest_face_data.index
		print(closest_face_data.position.distance_to(ball.transform.origin))
		update_tangent_transform()
		transform_to_new_face()

		var forward_vector = tangent_space_rotation * Vector3.FORWARD
		var flat_vector = forward_vector
		flat_vector.y = 0.0
		flat_vector = flat_vector.normalized()
		tangent_space_rotation = quaternion_look_at(flat_vector,Vector3.DOWN)
		set_ball_transform()
	tangent_space_position.y = 0.0
	
	
#	if Input.is_action_pressed("brake"):
#		var forward_vector = tangent_space_rotation * Vector3.FORWARD
#		var flat_vector = forward_vector
#		flat_vector.y = 0.0
#		flat_vector = flat_vector.normalized()
#		tangent_space_rotation = quaternion_look_at(flat_vector,Vector3.DOWN)
#		set_ball_transform()


#	var quat1 = Quat(0.2,1.2,3.2,5.1).normalized()
##	var quat2 = Quat(0.4,1.1,1.5,3.1).normalized()
#	var quat2 = quaternion_look_at(quat1 * Vector3.FORWARD)
#
#	ball.transform = Transform(quat1.slerp(quat2,sin(time)/2.0 + 0.5))
