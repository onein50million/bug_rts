extends Spatial

class_name Unit

var is_selected: bool = false

var turn = 0.0

export var surface_path: NodePath
onready var surface = get_node(surface_path)

var tangent_space_position: Vector3 = Vector3.ZERO
var tangent_space_rotation: Quat = Quat(Vector3.FORWARD, 0.0)
var current_face = 0

var tangent_space_transform = Transform.IDENTITY

func quaternion_look_at(vector: Vector3, up: Vector3) -> Quat:
	var basis = Basis(vector.cross(up),up,vector)
	return basis.orthonormalized().get_rotation_quat().normalized()

func update_transform():
	transform.origin = tangent_space_transform * tangent_space_position
	transform.basis = (tangent_space_transform * Transform(tangent_space_rotation)).basis


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
	
func _ready():

	current_face = randi() % surface.mesh_tool.get_face_count()
	update_tangent_transform()
	update_transform()
	print(transform.origin)
	
func _process(delta):
	
	if is_selected:
		print("selected!")
		$MeshInstance.get_active_material(0).albedo_color = Color(1.0,0.2,0.2,1.0)
		print($MeshInstance.get_active_material(0).albedo_color)
	else:
		$MeshInstance.get_active_material(0).albedo_color = Color(1.0,1.0,1.0,1.0)
	
	var calculated_world_rotation = (tangent_space_transform * Transform(tangent_space_rotation)).basis
	
	turn = (int(Input.is_action_pressed("left")) - int(Input.is_action_pressed("right"))) * delta * 2.0
	
	var movement = (int(Input.is_action_pressed("forward")) - int(Input.is_action_pressed("reverse"))) * delta * 0.3
	tangent_space_rotation *= Quat(Vector3(0.0,turn,0.0))
#	print(tangent_space_rotation.xform(Vector3.FORWARD * movement * delta).length())
#	print(delta)
	tangent_space_position += tangent_space_rotation.xform(Vector3.FORWARD * movement)

	var calculated_world_position = tangent_space_transform * tangent_space_position
#	tangent_space_position = tangent_space_transform.inverse() * (calculated_world_position + Vector3.UP * delta)

	update_transform()
	var closest_face_data = surface.get_closest_face_data(transform.origin)
	if current_face != closest_face_data.index:
		current_face = closest_face_data.index
		update_tangent_transform()
		transform_to_new_face()

		var forward_vector = tangent_space_rotation * Vector3.FORWARD
		var flat_vector = forward_vector
		flat_vector.y = 0.0
		flat_vector = flat_vector.normalized()
		tangent_space_rotation = quaternion_look_at(flat_vector,Vector3.DOWN)
		update_transform()
	tangent_space_position.y = 0.0
