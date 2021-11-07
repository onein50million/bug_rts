extends Spatial

class_name Unit

var is_selected: bool = false

var movement = 0.0

export var surface_path: NodePath
onready var surface = get_node(surface_path)

var random_turn = 0.0
var random_turn_cooldown = 1.0

var tangent_space_position: Vector3 = Vector3.ZERO
var tangent_space_rotation: Quat = Quat(Vector3.FORWARD, 0.0)
var current_face = 0

var tangent_space_transform = Transform.IDENTITY
var tangent_transform_inverse = Transform.IDENTITY
var orders = []

enum OrderType {Move}

class Order:
	var type
	var data
	var main_scene: Node
	var order_node: MeshInstance
	func _init(_order_type, _main_scene: Node):
		var order_scene = preload("res://OrderMarker.tscn")
		type = _order_type
		main_scene = _main_scene
		order_node = order_scene.instance()
		main_scene.add_child(order_node)
		match _order_type:
			OrderType.Move:
				data = {
					target = Vector3.ZERO
				}
	func update_order():
		order_node.transform.origin = data.target
	func remove_order():
		main_scene.remove_child(order_node)
		order_node.queue_free()
		


func quaternion_look_at(vector: Vector3, up: Vector3) -> Quat:
	var basis = Basis(vector.cross(up),up,vector).orthonormalized()
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
	tangent_transform_inverse = tangent_space_transform.inverse()

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

func new_orders(order: Order):
	orders.append(order)

func clear_orders():
	for order in orders:
		order.remove_order()
	orders.clear()

#returns true if order is finished
func process_order(order: Order) -> bool:
	match order.type:
		OrderType.Move:
			var direction = tangent_transform_inverse * order.data.target - tangent_transform_inverse * transform.origin
			
			var distance_to_go = order.data.target.distance_to(transform.origin)
			var order_complete = distance_to_go < rand_range(-0.1,0.1) and randf() > 0.95
			if not order_complete:
				tangent_space_rotation = tangent_space_rotation.slerp(quaternion_look_at(direction.normalized(), Vector3.DOWN),0.03)
				movement = 0.5
			return order_complete
		_:
			return true

func _ready():
	current_face = randi() % surface.mesh_tool.get_face_count()
	update_tangent_transform()
	update_transform(0.0)

func _process(delta):
	movement = 0.0
	$Selection.visible = is_selected
	for order in orders:
		order.order_node.visible = is_selected
	
#	tangent_space_rotation = transform.looking_at(target, Vector3.UP).basis.get_rotation_quat()
	if orders.size() > 0:
		if process_order(orders[0]):
			var removed_order: Unit.Order= orders.pop_front() #might get slow, should look into
			removed_order.remove_order()
	
	

	if random_turn_cooldown	<= 0.0:
		random_turn_cooldown = 1.0
		var random_range = 0.01
		random_turn = rand_range(-random_range, random_range)
	else:
		random_turn_cooldown -= 1.0 * delta* rand_range(0.5,3.0)
	tangent_space_rotation = tangent_space_rotation.slerp(tangent_space_rotation * Quat(Vector3(0.0,random_turn, 0.0)),random_turn_cooldown)
	tangent_space_position += tangent_space_rotation.xform(Vector3.FORWARD * movement * delta)
	tangent_space_position.y = 0.0
	
	update_transform(1.0)

	var inside_triangle = surface.is_inside_triangle(transform.origin, current_face)
	if not inside_triangle:
		var closest_face_data = surface.get_closest_face_data(transform.origin)

		if closest_face_data.index == -1:
			print("Invalid face, resetting position")
			reset_position()
			closest_face_data.index = current_face

		current_face = closest_face_data.index
		update_tangent_transform()
		transform_to_new_face()
		
		var forward_vector = tangent_space_rotation * Vector3.FORWARD
		var flat_vector = forward_vector
		flat_vector.y -= flat_vector.y * 0.0 * delta
		flat_vector = flat_vector.normalized()
		tangent_space_rotation = quaternion_look_at(flat_vector,Vector3.DOWN)
		update_transform(1.0)



