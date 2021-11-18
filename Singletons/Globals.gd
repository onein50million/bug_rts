extends Node


var enemy_team_count:int
var player_starting_position:Vector3
var player_team_name: String
var player_team_color: Color

var player_team: Team = null

var main_node: Node = null

enum CursorState{
	Select, #Default
	Move,
	Attack,
	Build
}
var cursor_state = CursorState.Select
var old_cursor_state

var selected_build_unit = null
var build_ghost: Spatial = null

enum UnitType {Bug, Queen, Enzyme, Blood, Factory,}

var unit_lookup = {}
var unit_scenes = {}
enum OrderType {Move, AttackUnit, AttackMove, BuildUnit}

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
			OrderType.BuildUnit:
				data = {
					unit_type = null,
					position = Vector3.ZERO,
					ghost = null,
				}
	func update_order():
		match type:
			OrderType.Move:
				order_node.transform.origin = data.target
			OrderType.AttackUnit:
				order_node.transform.origin = data.target.transform.origin
			OrderType.BuildUnit:
				if is_instance_valid(data.ghost):
					order_node.add_child(data.ghost)
		order_node.order_type = type
		order_node.order_data = data
	
	func remove_order():
		main_scene.remove_child(order_node)
		order_node.queue_free()
		


class Team:
	var color: Color
	var team_name: String
	
	var blood: float = 0.0
	var enzymes: float = 0.0
	
	var units = []
	
	var starting_face
	
	var queen
	
	var bug_kills = 0
	var queen_kills = 0
	
	const prefix = [
		"Super Cool",
		"Awesome",
		"Lame",
		"Retro",
		"Crepuscular",
		"Slithering",
	]
	const stem = [
		"Bugs",
		"Insects",
		"Spiders",
		"Beetles",
		"Creepy Crawlers",
		"Scorpions",
		"Ants",
		"Worms",
		"Bloodsuckers",
		"Hunters",
	]
		
	func _init():
		color = Color.from_hsv(randf(), 0.7, 1.0)
		team_name = prefix[randi() % prefix.size()] + " " + stem[randi() % stem.size()]


func _init():
	unit_scenes[UnitType.Bug] = load("res://Units/bug.tscn")
	unit_scenes[UnitType.Queen] = load("res://Units/bug_queen.tscn")
	unit_scenes[UnitType.Blood] = load("res://Units/Buildings/Economy/Hematoph/Hematoph.tscn")
	unit_scenes[UnitType.Enzyme] = load("res://Units/Buildings/Economy/EnzymeGland/EnzymeGland.tscn")
	unit_scenes[UnitType.Factory] = load("res://Units/Buildings/Construction/bug_factory.tscn")
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
			CursorState.Build:
				Input.set_custom_mouse_cursor(preload("res://Cursors/build.png"))
