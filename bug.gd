extends Spatial

class_name Unit

var is_selected: bool = false

var target: Vector3 = Vector3(1.0,1.0,1.0)

var movement = 0.0

export var surface_path: NodePath
onready var surface = get_node(surface_path)

var tangent_space_position: Vector3 = Vector3.ZERO
var tangent_space_rotation: Quat = Quat(Vector3.FORWARD, 0.0)
var current_face = 0

var tangent_space_transform = Transform.IDENTITY

func quaternion_look_at(vector: Vector3, up: Vector3) -> Quat:
	var basis = Basis(vector.cross(up),up,vector)
	return basis.get_rotation_quat()
	
func update_transform(interpolation_amount):
	var new_transform = Transform((tangent_space_transform * Transform(tangent_space_rotation)).basis,tangent_space_transform * tangent_space_position)
	transform = transform.interpolate_with(new_transform,interpolation_amount)

func update_tangent_transform():
	var normal = surface.mesh_tool.get_face_normal(current_face)
	var tangent = surface.get_face_tangent(current_face)
	var bitangent = normal.cross(tangent)
	var basis = Basis(bitangent, normal, tangent).orthonormalized()
	tangent_space_transform = Transform(basis, surface.get_face_position(current_face)).orthonormalized()

func transform_to_new_face():
	tangent_space_position = tangent_space_transform.inverse() * transform.origin
	var new_rotation: Quat = (tangent_space_transform.inverse() * Transform(transform.basis)).basis.get_rotation_quat()
	tangent_space_rotation = new_rotation

func reset_position():
	tangent_space_position = Vector3.ZERO
	tangent_space_rotation = Quat.IDENTITY
	current_face = randi() % surface.mesh_tool.get_face_count()
	update_tangent_transform()
	update_transform(0.0)

func flatten_quaternion(quaternion: Quat):
	var forward_vector = quaternion * Vector3.FORWARD
	var flat_vector = forward_vector
	flat_vector.y = 0.0
	flat_vector = flat_vector.normalized()
	return quaternion_look_at(flat_vector,Vector3.DOWN)

func new_orders(new_target):
	if is_selected:
		var spread = 0.1
		var random_vector = Vector3(rand_range(-spread,spread),rand_range(-spread,spread),rand_range(-spread,spread))
		target = surface.project_point(current_face, new_target + random_vector)

func _ready():
	current_face = randi() % surface.mesh_tool.get_face_count()
	update_tangent_transform()
	update_transform(0.0)

func _process(delta):
	
	$Selection.visible = is_selected
	
#	tangent_space_rotation = transform.looking_at(target, Vector3.UP).basis.get_rotation_quat()  

	var tangent_transform_inverse = tangent_space_transform.inverse()
	
	var direction = tangent_transform_inverse * target - tangent_transform_inverse * transform.origin
	var distance_to_go = target.distance_to(transform.origin)
	tangent_space_rotation = tangent_space_rotation.slerp(quaternion_look_at(direction.normalized(), Vector3.DOWN),0.2)
	movement = 0.5
	if distance_to_go > 0.1:
		tangent_space_position += tangent_space_rotation.xform(Vector3.FORWARD * movement * delta)

	update_transform(1.0)

	var inside_triangle = surface.is_inside_triangle(transform.origin, current_face)
	if not inside_triangle:
		var closest_face_data = surface.get_closest_face_data(transform.origin)

		if closest_face_data.index == -1:
			reset_position()
			closest_face_data.index = current_face

		current_face = closest_face_data.index
		update_tangent_transform()
		transform_to_new_face()
		
		var forward_vector = tangent_space_rotation * Vector3.FORWARD
		var flat_vector = forward_vector
		flat_vector.y = 0.0
		flat_vector = flat_vector.normalized()
		tangent_space_rotation = quaternion_look_at(flat_vector,Vector3.DOWN)
		update_transform(0.2)

	tangent_space_position.y = 0.0



