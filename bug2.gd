extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


func reset_position():
	transform.origin.y = 10.0
	get_parent().get_node("front_left_wheel/wheel_rigid").transform.origin.y = 10.0
	get_parent().get_node("front_right_wheel/wheel_rigid").transform.origin.y = 10.0
	get_parent().get_node("back_left_wheel/wheel_rigid").transform.origin.y = 10.0
	get_parent().get_node("back_right_wheel/wheel_rigid").transform.origin.y = 10.0
	rotation = Vector3.ZERO
	get_parent().get_node("front_left_wheel/wheel_rigid").rotation = Vector3.ZERO
	get_parent().get_node("front_right_wheel/wheel_rigid").rotation = Vector3.ZERO
	get_parent().get_node("back_left_wheel/wheel_rigid").rotation = Vector3.ZERO
	get_parent().get_node("back_right_wheel/wheel_rigid").rotation = Vector3.ZERO
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


func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		reset_position()


func _physics_process(delta):
	var throttle = 50*(int(Input.is_action_pressed("forward")) - int(Input.is_action_pressed("reverse")))
	
	var steering_amount = 30
	var target_steering = steering_amount*(int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left")))

	
	var steering_axles = [
		get_parent().get_node("front_left_wheel").get_node("axle"),
		get_parent().get_node("front_right_wheel").get_node("axle"),
	]
	
	var power_axles = [
		get_parent().get_node("front_left_wheel").get_node("axle"),
		get_parent().get_node("front_right_wheel").get_node("axle"),
		get_parent().get_node("back_left_wheel").get_node("axle"),
		get_parent().get_node("back_right_wheel").get_node("axle"),
	]
	for axle in steering_axles:
		axle["angular_spring_y/equilibrium_point"] = target_steering

	for axle in power_axles:
		axle["angular_motor_x/target_velocity"] = throttle
		axle["angular_motor_x/enabled"] = abs(throttle) > 1
			

