extends Button

var unit_type

func _ready():
	text = Globals.unit_lookup[unit_type].pretty_name

func _pressed():
	Globals.selected_build_unit = unit_type
	
	if Globals.build_ghost != null:
		Globals.build_ghost.queue_free()
		Globals.build_ghost = null
	Globals.build_ghost = Globals.unit_lookup[unit_type].get_node("Armature").duplicate()
	Globals.build_ghost.get_node("Skeleton/Mesh").mesh = Globals.build_ghost.get_node("Skeleton/Mesh").mesh.duplicate()
	Globals.build_ghost.add_child(Globals.unit_lookup[unit_type].get_node("GhostHitbox").duplicate())
	get_tree().root.get_node("Main").add_child(Globals.build_ghost)
