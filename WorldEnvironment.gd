extends WorldEnvironment


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#export var target_path: NodePath
#export var camera_path: NodePath
#onready var camera = get_node(camera_path)
#onready var target = get_node(target_path)
#export var blur_spread = 1.0
## Called when the node enters the scene tree for the first time.
#func _ready():
#	environment.dof_blur_far_enabled = true
#	environment.dof_blur_near_enabled = true
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	environment.dof_blur_far_distance = camera.transform.origin.distance_to(target.transform.origin) + blur_spread
#	environment.dof_blur_near_distance = camera.transform.origin.distance_to(target.transform.origin) - blur_spread
