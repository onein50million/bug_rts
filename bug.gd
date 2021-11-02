extends VehicleBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var target_steering = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	var front_left = $front_right.duplicate()
	var back_left = $front_right.duplicate()
	front_left.translation.x *= -1
	back_left.translation.x *= -1
	
	add_child(front_left)
	add_child(back_left)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var throttle = 200*(int(Input.is_action_pressed("forward")) - int(Input.is_action_pressed("reverse")))
	engine_force = throttle
	
	var steering_amount = PI/4.0
	var target_steering = steering_amount*(int(Input.is_action_pressed("left")) - int(Input.is_action_pressed("right")))
	
	
	var steering_difference = abs(target_steering - steering)
	
	if target_steering > steering:
		steering += steering_amount*delta * 4 * steering_difference
	elif target_steering < steering:
		steering -= steering_amount*delta * 4 * steering_difference
	
	steering = clamp(steering,-steering_amount,steering_amount)
	
