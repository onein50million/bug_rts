extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var car: NodePath

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	transform.origin.x = get_node(car).get_node("body").transform.origin.x
	transform.origin.z = get_node(car).get_node("body").transform.origin.z

	
