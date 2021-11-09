extends Camera


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var target_path: NodePath

var gimbal_radius = 25.0
var gimbal_angle = 0.0
var yaw = 0.0
var pitch = 0.0
var height = 10.0


var zoom_ratio = 1.0
var camera_position = transform.origin


var vertical_sensitivity = 0.5
var horizontal_sensitivity = 0.5

var alt_vertical_sensitivity = 20.0
var alt_horizontal_sensitivity = 5.0
# Called when the node enters the scene t e for the first time.
func _ready():
	pass

func _input(event):
	if event.is_action_pressed("middle_click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	if event.is_action_released("middle_click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseMotion and Input.is_action_pressed("middle_click"):
		var mouse_x = (event.relative.x / get_viewport().size.x) * clamp(zoom_ratio,0.0, 1.0)
		var mouse_y = (event.relative.y / get_viewport().size.y) * clamp(zoom_ratio,0.0, 1.0)
		if Input.is_action_pressed("view_modifier"):
			gimbal_angle -= mouse_x * alt_horizontal_sensitivity
			height += mouse_y * alt_vertical_sensitivity 
			pitch = atan2(tan(pitch)*gimbal_radius - (mouse_y * alt_vertical_sensitivity), gimbal_radius)
		else:
			yaw += mouse_x * vertical_sensitivity 
			pitch += mouse_y * horizontal_sensitivity


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	height += (int(Input.is_action_pressed("camera_up")) - int(Input.is_action_pressed("camera_down"))) * 20.0 * delta
	gimbal_angle += (int(Input.is_action_pressed("camera_right")) - int(Input.is_action_pressed("camera_left"))) * 2.0 * delta
	camera_position = Quat(Vector3(0.0,gimbal_angle, 0.0)) * Vector3(0.0, height, gimbal_radius)
	
	var angular_size = PI/32.0
	if not target_path.is_empty():
		var target = get_node(target_path)
		var target_position = target.transform.origin
		var distance_to_target = transform.origin.distance_to(target_position)
		var target_size = abs(target.get_node("MeshInstance").get_aabb().get_longest_axis_size())
		look_at_from_position(camera_position,target_position,Vector3.UP)
		angular_size = 2.0 * atan2(target_size, 2.0 * distance_to_target)
	else:
		look_at_from_position(camera_position, Vector3(0.0,height,0.0), Vector3.UP)
		transform.basis *= Basis(Vector3(pitch,yaw, 0.0))
	var zoom_input = int(Input.is_action_just_released("zoom_out")) - int(Input.is_action_just_released("zoom_in"))
	zoom_ratio *= 1.0 + float(zoom_input) * 0.3
	


	var new_fov = rad2deg(angular_size*zoom_ratio)
	set_perspective(new_fov, near, far)
	
	

