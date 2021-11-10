extends Spatial

class_name Unit

var is_selected: bool = false

var IS_UNIT = true

var speed = 0.5
var movement = 0.0

var max_health = 100.0
var health = max_health

var last_damage_source_team: Globals.Team

onready var surface = get_tree().get_nodes_in_group("surface")[0]
var random_turn = 0.0
var random_turn_cooldown = 1.0

var tangent_space_position: Vector3 = Vector3.ZERO
var tangent_space_rotation: Quat = Quat(Vector3.FORWARD, 0.0)
var current_face = 0

var attack_time = 2.0
var current_attack = 0.0
var damage = 10.0

var tangent_space_transform = Transform.IDENTITY
var tangent_transform_inverse = Transform.IDENTITY
var orders = []
var team

var enemy_contextual_order = Globals.OrderType.AttackUnit
var friendly_contextual_order = Globals.OrderType.Move
var unit_type = Globals.UnitType.Bug

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
	current_face = surface.get_closest_face(transform.origin).index
	update_tangent_transform()
	update_transform(1.0)

func flatten_quaternion(quaternion: Quat):
	var forward_vector = quaternion * Vector3.FORWARD
	var flat_vector = forward_vector
	flat_vector.y = 0.0
	flat_vector = flat_vector.normalized()
	return quaternion_look_at(flat_vector,Vector3.DOWN)

func new_orders(order: Globals.Order):
	orders.append(order)

func clear_orders():
	for order in orders:
		order.remove_order()
	orders.clear()

#returns true if order is finished
func process_order(order: Globals.Order) -> bool:
	match order.type:
		Globals.OrderType.Move:
			var direction = tangent_transform_inverse * order.data.target - tangent_transform_inverse * transform.origin
			
			var distance_to_go = order.data.target.distance_to(transform.origin)
			var order_complete = distance_to_go < rand_range(-0.1,0.1) and randf() > 0.95
			if not order_complete:
				#sometimes direction vector is zero so a small vector needs to be added
				tangent_space_rotation = tangent_space_rotation.slerp(quaternion_look_at(direction.normalized() + Vector3.ONE * 0.0001 , Vector3.DOWN),0.1)
			return order_complete
		Globals.OrderType.AttackUnit:
			if not is_instance_valid(order.data.target):
				return true
			var target_direction = (tangent_transform_inverse * surface.project_point(current_face, order.data.target.transform.origin) - tangent_transform_inverse * transform.origin).normalized()
			tangent_space_rotation = quaternion_look_at(target_direction, Vector3.DOWN)
			return false
		_:
			print("Unimplemented Order")
			return true

func die():
#	print("DEATH on team: %s" % team.team_name)
	if last_damage_source_team:
		last_damage_source_team.bug_kills += 1
	clear_orders()
	team.units.erase(self)
	queue_free()

func attack(other:Unit):
	if current_attack < 0.0 and other.team != team:
		other.last_damage_source_team = team
		other.health -= damage
		current_attack = attack_time
#		tangent_space_position += tangent_space_rotation.xform(Vector3.BACK * 0.05)

func _ready():
#	current_face = randi() % surface.mesh_tool.get_face_count()
	assert(has_node("Hitbox"))
	assert(has_node("SelectHitbox"))
	update_tangent_transform()
	update_transform(1.0)

func _enter_tree():
	var mesh_outline = $MeshInstance.mesh.create_outline(0.001)
	
	var highlight_mesh = $MeshInstance.duplicate()
	highlight_mesh.mesh = mesh_outline
#	highlight_mesh.transform.scaled(Vector3(1.1,1.1,1.1))
	highlight_mesh.set_surface_material(0, highlight_mesh.get_active_material(0).duplicate())
	highlight_mesh.get_active_material(0).flags_unshaded = true
#	highlight_mesh.get_active_material(0).params_cull_mode = SpatialMaterial.CULL_FRONT
	highlight_mesh.get_active_material(0).albedo_color = team.color
	add_child(highlight_mesh)

func _process(delta):

	if health < 0.0:
		die()
	if not is_instance_valid(team.queen) and randf() > 0.99:
		die()
	movement = speed * 0.2
	$Selection.visible = is_selected
	for order in orders:
		order.order_node.visible = is_selected
	
#	tangent_space_rotation = transform.looking_at(target, Vector3.UP).basis.get_rotation_quat()
	if orders.size() > 0:
		if process_order(orders[0]):
			var removed_order: Globals.Order= orders.pop_front() #might get slow, should look into
			removed_order.remove_order()
		else:
			movement = speed #SPEED if order isn't done yet
	if random_turn_cooldown	<= 0.0:
		random_turn_cooldown = 1.0
		var random_range = 0.05
		random_turn = rand_range(-random_range, random_range)
	else:
		random_turn_cooldown -= 1.0 * delta* rand_range(0.5,3.0)
	tangent_space_rotation = tangent_space_rotation.slerp(tangent_space_rotation * Quat(Vector3(0.0,random_turn, 0.0)),random_turn_cooldown)
	tangent_space_position += tangent_space_rotation.xform(Vector3.FORWARD * movement * delta)
	tangent_space_position.y = 0.0
	
	update_transform(1.0)

	var inside_triangle = surface.is_inside_triangle(transform.origin, current_face)
	if not inside_triangle:

		var closest_face_data = surface.get_standing_face(transform.origin)
		if closest_face_data.index == -1:
			print("Invalid face, resetting position")
			reset_position()
			closest_face_data.index = current_face

		current_face = closest_face_data.index
		update_tangent_transform()
		transform_to_new_face()
		
		var forward_vector = tangent_space_rotation * Vector3.FORWARD
		var flat_vector = forward_vector
		flat_vector.y *= 0.0
		flat_vector = flat_vector.normalized()
		tangent_space_rotation = quaternion_look_at(flat_vector,Vector3.DOWN)
		update_transform(1.0)

func _physics_process(delta):
	current_attack -= delta
	for area in $Hitbox.get_overlapping_areas():
		var parent = area.get_parent()
		if "IS_UNIT" in parent and IS_UNIT:
			attack(parent)
