extends Area

func _ready():
	$CollisionShape.shape.call_deferred("set_radius",get_parent().get_node("Armature/Skeleton/Mesh").mesh.get_aabb().get_shortest_axis_size())
