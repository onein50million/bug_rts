extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"



# Called when the node enters the scene tree for the first time.
func _ready():
#	var front_left = $front_right.duplicate()
#	var back_left = $front_right.duplicate()
#	front_left.translation.x *= -1
#	back_left.translation.x *= -1
#
#	add_child(front_left)
#	add_child(back_left)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var throttle = 50*(int(Input.is_action_pressed("forward")) - int(Input.is_action_pressed("reverse")))
	add_central_force(-transform.basis.z * throttle)
	
	var steering_amount = 30
	var target_steering = steering_amount*(int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left")))

	
	var steering_axles = [
		get_parent().get_node("front_left_wheel").get_node("axle"),
		get_parent().get_node("front_right_wheel").get_node("axle"),
	]
	for axle in steering_axles:
		axle["angular_spring_y/equilibrium_point"] = target_steering
#		print(axle["angular_spring_y/equilibrium_point"])

