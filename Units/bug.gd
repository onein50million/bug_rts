extends Spatial

class_name Unit

var is_selected: bool = false
var has_played_select_noise: bool = false

var IS_UNIT = true

var is_placed = false

var build_animation_name: String = ""
var start_animation_name: String = ""
var idle_animation_name: String = ""

var pretty_name: String = "Bug"

var buildable_units = []

var friendly_fire_enabled = false #so that we can break out when stuck

var speed = 0.04
var movement = 0.0

var smoothness = 0.99

var max_health = 30.0
var health

var allocated_enzyme_ratio = 0.0 #Game allocates resources to units so that they can still build while sharing them
var allocated_blood_ratio = 0.0

var enzyme_output = 5.0 #how many resources it uses to build things
var blood_output = 0.5

var stored_blood = 0.0
var stored_enzyme = 0.0

var blood_cost = 10.0
var enzyme_cost = 1.0

var can_turn = true

var blood_production = 0.0
var enzyme_production = 0.0

var camera: Camera

var munch_sound = AudioStreamPlayer3D.new()

var last_damage_source_team: Globals.Team
onready var surface = get_tree().get_nodes_in_group("surface")[0]
var random_turn = 0.0
var random_turn_cooldown = 1.0

var build_range = 0.05

var tangent_space_position: Vector3 = Vector3.ZERO
var tangent_space_rotation: Quat = Quat(Vector3.FORWARD, 0.0)
var current_face = 0

var velocity:Vector3 = Vector3.ZERO

var attack_time = 2.0
var current_attack = 0.0
var damage = 10.0

var tangent_space_transform = Transform.IDENTITY
var tangent_transform_inverse = Transform.IDENTITY
var orders = []
var team: Globals.Team

var enemy_contextual_order = Globals.OrderType.AttackUnit
var friendly_contextual_order = Globals.OrderType.Move
var unit_type = Globals.UnitType.Bug

var unit_label: Control
var health_bar: ProgressBar
var construction_bar: ProgressBar
var num_guts = 10
var gut_velocity = 0.1

var next_point

func quaternion_look_at(vector: Vector3, up: Vector3) -> Quat:
	if vector.is_equal_approx(Vector3.ZERO):
		vector = Vector3.UP
	var basis = Basis(vector.cross(up),up,vector).orthonormalized()
	return basis.get_rotation_quat()

func update_path_points(new_target:Vector3):
	
	var starting_point = surface.astar.get_closest_point(transform.origin)
	var ending_point = surface.astar.get_closest_point(new_target)
	var new_point_path:PoolVector3Array = surface.astar.get_point_path(starting_point, ending_point)

	if new_point_path.size() > 1:
		next_point = new_point_path[1]
	else:
		next_point = null

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
	if has_node("EnzymeParticles"):
		get_node("EnzymeParticles").emitting = false
	if has_node("BloodParticles"):
		get_node("BloodParticles").emitting = false
	friendly_fire_enabled = false
	for order in orders:
		order.remove_order()
	orders.clear()

#returns true if order is finished
func process_order(order: Globals.Order, delta) -> bool:
	movement = speed/2.0 if current_attack > 0.0 else speed #SPEED if order isn't done yet
	match order.type:
		Globals.OrderType.Move:
			if speed < 0.01:
				return true 
			
			var distance_to_next_point = next_point.distance_to(transform.origin) if next_point != null else 0.0
			if distance_to_next_point < 0.01:
				update_path_points(order.data.target)
			var direction
			if next_point != null:
				direction = tangent_transform_inverse * next_point - tangent_transform_inverse * transform.origin
			else:
				direction = tangent_transform_inverse * order.data.target - tangent_transform_inverse * transform.origin
			
			var distance_to_go = order.data.target.distance_to(transform.origin)
			var order_complete = distance_to_go < rand_range(0.0,0.01) and randf() > 0.95
			if not order_complete and can_turn:
				#sometimes direction vector is zero so a small vector needs to be added
				tangent_space_rotation = tangent_space_rotation.slerp(quaternion_look_at(direction.normalized() + Vector3.ONE * 0.0001 , Vector3.DOWN),0.2)
			return order_complete
		Globals.OrderType.AttackUnit:
			if not is_instance_valid(order.data.target):
				friendly_fire_enabled = false
				return true
			var distance_to_next_point = next_point.distance_to(transform.origin) if next_point != null else 0.0
			if distance_to_next_point < 0.01:
				update_path_points(order.data.target.transform.origin)
			var direction
			if next_point != null:
				direction = tangent_transform_inverse * next_point - tangent_transform_inverse * transform.origin
			else:
				direction = tangent_transform_inverse * order.data.target.transform.origin - tangent_transform_inverse * transform.origin
			if can_turn:
				tangent_space_rotation = quaternion_look_at(direction.normalized(), Vector3.DOWN)
			return false
		Globals.OrderType.BuildUnit:
			construction_bar.value = min(stored_blood / Globals.unit_lookup[order.data.unit_type].blood_cost,stored_enzyme / Globals.unit_lookup[order.data.unit_type].enzyme_cost)
			if not Globals.unit_lookup[order.data.unit_type].is_placed or (Globals.unit_lookup[order.data.unit_type].is_placed and transform.origin.distance_to(order.data.position) < build_range):
				assert(order.data.unit_type in buildable_units)
				if has_node("EnzymeParticles"):
					get_node("EnzymeParticles").emitting = true
				if has_node("BloodParticles"):
					get_node("BloodParticles").emitting = true
				if can_turn:
					tangent_space_rotation =  quaternion_look_at((tangent_transform_inverse * order.data.position - tangent_transform_inverse * transform.origin).normalized(), Vector3.DOWN)
				movement = 0.0
				var used_blood = blood_output * delta * allocated_blood_ratio
				team.blood -= used_blood
				allocated_blood_ratio = 0.0
				stored_blood += used_blood
				
				var used_enzyme = enzyme_output * delta * allocated_enzyme_ratio
				team.enzymes -= used_enzyme
				allocated_enzyme_ratio = 0.0
				stored_enzyme += used_enzyme
				
				if stored_blood > Globals.unit_lookup[order.data.unit_type].blood_cost and stored_enzyme > Globals.unit_lookup[order.data.unit_type].enzyme_cost:
					var spawn_transform = transform if not Globals.unit_lookup[order.data.unit_type].is_placed else order.data.ghost.transform
					surface.spawn_bug(spawn_transform,order.data.unit_type, team)
					stored_blood -= Globals.unit_lookup[order.data.unit_type].blood_cost
					stored_enzyme -= Globals.unit_lookup[order.data.unit_type].enzyme_cost
					if has_node("EnzymeParticles"):
						get_node("EnzymeParticles").emitting = false
					if has_node("BloodParticles"):
						get_node("BloodParticles").emitting = false
					return true
			elif Globals.unit_lookup[order.data.unit_type].is_placed: #If we aren't close enough to place it
				
				var distance_to_next_point = next_point.distance_to(transform.origin) if next_point != null else 0.0
				if distance_to_next_point < 0.01:
					update_path_points(order.data.position)
				var direction
				if next_point != null:
					direction = tangent_transform_inverse * next_point - tangent_transform_inverse * transform.origin
				else:
					direction = tangent_transform_inverse * order.data.position - tangent_transform_inverse * transform.origin
				if can_turn:
					tangent_space_rotation = quaternion_look_at(direction.normalized(), Vector3.DOWN)
			return false
		_:
			print("Unimplemented Order")
			return true

func die():
	var splat_sound = AudioStreamPlayer3D.new()
	splat_sound.stream = preload("res://Sounds/splat.ogg")
	splat_sound.unit_db = lerp(75,60, camera.zoom_ratio)
	if unit_type == Globals.UnitType.Queen:
		splat_sound.unit_db += 10
		splat_sound.bus = "Reverb"
	get_parent().add_child(splat_sound)
	splat_sound.play()
	
	for _i in range(0,num_guts):
		var gut = preload("res://guts.tscn").instance()
		get_parent().add_child(gut)
		gut.transform.origin = transform.origin + transform.basis.y*0.01
		var velocity_range = gut_velocity
		gut.linear_velocity += Vector3(rand_range(-velocity_range,velocity_range),rand_range(-velocity_range,velocity_range),rand_range(-velocity_range,velocity_range))
		var scale_range = 0.1
		gut.scale = Vector3(rand_range(0.2 - scale_range, 0.2+scale_range),rand_range(0.2 - scale_range, 0.2+scale_range),rand_range(0.2 - scale_range, 0.2+scale_range))
	
#	print("DEATH on team: %s" % team.team_name)
	if last_damage_source_team:
		last_damage_source_team.bug_kills += 1
	clear_orders()
	team.units.erase(self)
	queue_free()

func attack(other:Unit):
	if current_attack < 0.0 and (other.team != team) and damage > 0.1:
#	if current_attack < 0.0 and (other.team != team or friendly_fire_enabled):
		munch_sound.unit_db = lerp(80,70, camera.zoom_ratio)
		if unit_type == Globals.UnitType.Queen:
			munch_sound.unit_db += 10
			munch_sound.bus = "Reverb"
		munch_sound.pitch_scale = rand_range(0.9,1.1)
		munch_sound.play()
		
		var bite_effect = preload("res://BiteEffect.tscn").instance()
		bite_effect.camera = camera
		bite_effect.world_position = (other.transform.origin + transform.origin)/2.0
		get_node("/root/Main").add_child(bite_effect)
		bite_effect.transform.origin = camera.unproject_position(other.transform.origin)
		
		current_attack = attack_time*rand_range(0.9,1.1)
		other.last_damage_source_team = team
		other.health -= damage*rand_range(0.9,1.1)
	
#func _init():
#	if not has_node("GhostHitbox"):
#		push_error("GhostHitbox not found, generating")
#		var ghost_hitbox = Area.new()
#		ghost_hitbox.collision_layer = 0b1000
#		ghost_hitbox.collision_mask = 0b1000
#		ghost_hitbox.name = "GhostHitbox"
#		var collision_shape = CollisionShape.new()
#		collision_shape.name = "CollisionShape"
#		var shape: Shape = SphereShape.new()
#		collision_shape.shape = shape
#		ghost_hitbox.add_child(collision_shape)
#		add_child(ghost_hitbox)

func _ready():
	health = max_health
#	current_face = randi() % surface.mesh_tool.get_face_count()
	assert(has_node("Hitbox"))
	assert(has_node("SelectHitbox"))
	assert(has_node("GhostHitbox"))
	
	munch_sound.stream = preload("res://Sounds/munch.ogg")
	add_child(munch_sound)
#	get_node("GhostHitbox/CollisionShape").shape = get_node("Hitbox/CollisionShape").shape.duplicate()
#	get_node("GhostHitbox/CollisionShape").transform = get_node("Hitbox/CollisionShape").transform.scaled(Vector3(1.5,1.5,1.5))
	unit_label = preload("res://UI/UnitLabel.tscn").instance()
	add_child(unit_label)
	health_bar = unit_label.get_node("HealthBar")
	construction_bar = unit_label.get_node("ConstructionBar")
	unit_label.get_node("TeamIcon").modulate = team.color
	update_tangent_transform()
	transform_to_new_face()
	
	var forward_vector = tangent_space_rotation * Vector3.FORWARD
	var flat_vector = forward_vector
	flat_vector.y *= 0.0
	flat_vector = flat_vector.normalized()
	tangent_space_rotation = quaternion_look_at(flat_vector,Vector3.DOWN)
	
	update_transform(1.0)
	if start_animation_name != "":
		$AnimationPlayer.play(start_animation_name)
	if idle_animation_name != "":
		$AnimationPlayer.get_animation(idle_animation_name).loop = true
#		$AnimationPlayer.seek(rand_range(0.0,2.0))

#func _enter_tree():
#	var mesh_outline = $Armature/Skeleton/Mesh.mesh.create_outline(0.0002)
#
#	var highlight_mesh = $Armature/Skeleton/Mesh.duplicate()
#	highlight_mesh.mesh = mesh_outline
##	highlight_mesh.transform.scaled(Vector3(1.1,1.1,1.1))
##	highlight_mesh.set_surface_material(0, highlight_mesh.get_active_material(0).duplicate())
#	var new_material = SpatialMaterial.new()
#	new_material.flags_unshaded = true
#	new_material.albedo_color = team.color
#	highlight_mesh.mesh.surface_set_material(0, new_material)
#	add_child(highlight_mesh)
	

func _process(delta):
	health_bar.visible = health < max_health
	health_bar.value = health / max_health
	construction_bar.visible = orders.size() > 0 and orders[0].type == Globals.OrderType.BuildUnit
	if health < 0.0:
		die()
	if not is_instance_valid(team.queen) and randf() > 0.99:
		die()
	
	team.enzymes += enzyme_production * delta
	team.blood += blood_production * delta
	
	$Selection.visible = is_selected
	for order in orders:
		order.order_node.visible = is_selected
	
	movement = speed * 0.2
#	tangent_space_rotation = transform.looking_at(target, Vector3.UP).basis.get_rotation_quat()
	if orders.size() > 0:
		if process_order(orders[0],delta):
			var removed_order: Globals.Order= orders.pop_front() #might get slow, should look into
			removed_order.remove_order()
	if idle_animation_name != "":
		if orders.size() < 1:
			$AnimationPlayer.play(idle_animation_name)
		else:
			$AnimationPlayer.stop(false)
	if build_animation_name != "":
		if orders.size() > 0 and orders[0].type == Globals.OrderType.BuildUnit:
			$AnimationPlayer.play(build_animation_name) 
		else:
			$AnimationPlayer.stop(false)
	
	if can_turn:
		if random_turn_cooldown	<= 0.0:
			random_turn_cooldown = 1.0
			var random_range = 0.5 * movement
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
	
	unit_label.rect_position = camera.unproject_position(transform.origin + transform.basis.y*0.01)
	if has_node("WalkPlayer"):
		$WalkPlayer.playing = movement > 0.1
		$WalkPlayer.unit_db = lerp(0.0,80, movement/speed)
	if is_selected:
		if has_node("SelectPlayer"):
			if not has_played_select_noise:
				$SelectPlayer.play(rand_range(0.0,0.1))
				$SelectPlayer.pitch_scale = rand_range(0.9,1.1)
				has_played_select_noise = true
	elif has_played_select_noise:
		has_played_select_noise = false
	health = min(health + 1.0*delta,max_health)
func _physics_process(delta):
#	velocity = Vector3.UP
#	if velocity.length() > 0.1:
#		print(velocity)
	tangent_space_position = tangent_transform_inverse * (tangent_space_transform * tangent_space_position + velocity * delta)
	current_attack -= delta
	for area in $Hitbox.get_overlapping_areas():
		var parent = area.get_parent()
		if "IS_UNIT" in parent and IS_UNIT:
#			print("%s vs %s" %[parent.name, name])
#			var velocity_magnitude = 0.01/(parent.transform.origin.distance_squared_to(transform.origin) + 0.00001)
			var velocity_direction = -(parent.transform.origin - transform.origin).normalized()
			var velocity_magnitude = 1.0
			velocity += velocity_direction * velocity_magnitude * 1.0 * delta
#			tangent_space_rotation = tangent_space_rotation.inverse()
#			print(velocity_magnitude)
#			parent.velocity -= velocity_direction * velocity_magnitude * 0.5
			attack(parent)
	velocity *= smoothness
