extends Area

func _ready():
	
	$CollisionShape.shape.call_deferred("set_radius",get_parent().get_node("MeshInstance").mesh.get_aabb().get_longest_axis_size())
