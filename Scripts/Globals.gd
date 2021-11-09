extends Node

enum CursorState{
	Select, #Default
	Move,
	Attack
}
var cursor_state = CursorState.Select
var old_cursor_state

enum UnitType {Bug, Queen, Jump}
enum OrderType {Move, AttackUnit, AttackMove}

class Order:
	var type
	var data
	var main_scene: Node
	var order_node: MeshInstance
	func _init(_order_type, _main_scene: Node):
		var order_scene = preload("res://OrderMarker.tscn")
		type = _order_type
		main_scene = _main_scene
		order_node = order_scene.instance() #TODO: make a pool so there isn't a big lag spike
		main_scene.add_child(order_node)
		match _order_type:
			OrderType.Move:
				data = {
					target = Vector3.ZERO
				}
			OrderType.AttackUnit:
				data = {
					target = null  #Unit
				}
			OrderType.AttackMove:
				data = {} #TBD
	func update_order():
		match type:
			OrderType.Move:
				order_node.transform.origin = data.target
			OrderType.AttackUnit:
				order_node.transform.origin = data.target.transform.origin
		order_node.order_type = type
		order_node.order_data = data
	
	func remove_order():
		main_scene.remove_child(order_node)
		order_node.queue_free()
		


class Team:
	var color: Color
	var team_name: String
	var units = []
	
	var queen
	
	var bug_kills = 0
	var queen_kills = 0
	
	const prefix = [
		"The Super Cool",
		"The Awesome",
		"The Lame",
		"The Retro",
		"The Crepuscular"
	]
	const stem = [
		"Bugs",
		"Insects",
		"Spiders",
		"Beetles",
		"Creepy Crawlers",
		"Scorpions",
		"Ants",
	]
		
	func _init():
		color = Color.from_hsv(randf(), 0.7, 1.0)
		team_name = prefix[randi() % prefix.size()] + " " + stem[randi() % stem.size()]


func _init():
	print("Globals Ready")

func _process(_delta):
	if old_cursor_state != cursor_state:
		old_cursor_state = cursor_state
		match cursor_state:
			CursorState.Select:
				Input.set_custom_mouse_cursor(preload("res://Cursors/default.png"))
			CursorState.Move:
				Input.set_custom_mouse_cursor(preload("res://Cursors/move.png"))
			CursorState.Attack:
				Input.set_custom_mouse_cursor(preload("res://Cursors/attack.png"))
