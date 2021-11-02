extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var is_steering = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$axle["nodes/node_a"] = get_parent().get_node("body").get_path()
	$axle["nodes/node_b"] = $wheel_rigid.get_path()
	
	if is_steering:
		$axle["angular_limit_y/upper_angle"] = 30
		$axle["angular_limit_y/lower_angle"] = -30
		$axle["angular_spring_y/enabled"] = true
		$axle["angular_spring_y/stiffness"] = 10
		$axle["angular_spring_y/damping"] = 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
