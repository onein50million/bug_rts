extends MeshInstance

onready var camera:Camera = get_parent().get_node("Camera")
onready var direct_space_state:PhysicsDirectSpaceState = get_world().direct_space_state
onready var selection = get_parent().get_node("Selection")
func _ready():
	set_process_input(true)
	$StaticBody/CollisionShape.shape = mesh.create_trimesh_shape()

func _input(event):
	if event.is_action_released("left_click"):
		var ray_origin = camera.project_ray_origin(get_viewport().get_mouse_position())
		var ray_target = ray_origin + camera.project_ray_normal(get_viewport().get_mouse_position()) * 1e6
		var raycast_result = direct_space_state.intersect_ray(ray_origin, ray_target)
		if not raycast_result.empty():
			Globals.player_starting_position = raycast_result.position
			selection.transform.origin = raycast_result.position
			var random_vector = Vector3(rand_range(-1.0,1.0),rand_range(-1.0,1.0),rand_range(-1.0,1.0)).normalized()
			selection.transform.basis = Basis(random_vector.cross(raycast_result.normal),raycast_result.normal,random_vector).orthonormalized()

