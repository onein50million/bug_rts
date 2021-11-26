extends Unit
class_name Building


func _init():
	self.speed = 0.0
	self.is_placed = true
	self.smoothness = 0.0
	self.can_turn = false
	self.pretty_name = "Building"
	self.damage = 0.0


func die():
	var astar: AStar = surface.astar
	astar.set_point_weight_scale(current_face, astar.get_point_weight_scale(current_face) - 100.0)
	.die()
func _ready():
	var astar: AStar = surface.astar
	astar.set_point_weight_scale(current_face, astar.get_point_weight_scale(current_face) + 100.0)
