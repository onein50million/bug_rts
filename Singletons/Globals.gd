extends Node


var enemy_team_count:int
var player_starting_position:Vector3
var player_team_name: String
var player_team_color: Color

var spectate = false

var player_team: Team = null

var main_node: Node = null

enum CursorState{
	Select, #Default
	Attack,
	Build
}
var cursor_state = CursorState.Select
var old_cursor_state

var selected_build_unit = null
var build_ghost: Spatial = null

enum UnitType {Bug, Queen, Enzyme, Blood, Factory,Worker}

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
		if not is_instance_valid(order_node):
			return
		match type:
			OrderType.Move:
				order_node.transform.origin = data.target
			OrderType.AttackUnit:
				if is_instance_valid(data.target):
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
	
	var ai: AI
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
		var index = randi() % Globals.colors.size()
		color = Globals.colors[index]
		Globals.colors.remove(index)
		team_name = prefix[randi() % prefix.size()] + " " + stem[randi() % stem.size()]

class AI:
	var team: Team
	
	var time = 0.0
	var update_time = 1.0
	
	var current_mode = Modes.BloodEconomy
	
	var last_queen_health = 0.0
	
	enum Modes{
		BloodEconomy,
		EnzymeEconomy,
		Production,
		Attack,
		Defend,
	}
	
	func attempt_to_place_building(unit, unit_type):

		var attempts_left = 100
		while attempts_left > 0:
			attempts_left -= 1
			var attempt_spread = 0.1
			var attempt_point = unit.transform.origin+Vector3(rand_range(-attempt_spread, attempt_spread),rand_range(-attempt_spread, attempt_spread),rand_range(-attempt_spread, attempt_spread))
			var new_building_face = Globals.main_node.surface.get_closest_face(attempt_point).index
			var new_building_position = Globals.main_node.surface.project_point(new_building_face, attempt_point)
			
			var direct_space_state: PhysicsDirectSpaceState = Globals.main_node.direct_space_state
			var shape_cast_parameters = PhysicsShapeQueryParameters.new()
			shape_cast_parameters.collide_with_areas = true
			shape_cast_parameters.collide_with_bodies = false
			shape_cast_parameters.collision_mask = 0b1000
			shape_cast_parameters.set_shape(Globals.unit_lookup[unit_type].get_node("GhostHitbox/CollisionShape").shape)
			var shape_cast_result = direct_space_state.intersect_shape(shape_cast_parameters)
			
			var can_place = shape_cast_result.size() < 1
			if can_place:
				var new_order = Order.new(OrderType.BuildUnit,Globals.main_node)
				new_order.data.unit_type = unit_type
				new_order.data.position = new_building_position
				
				var ghost = Globals.unit_lookup[unit_type].get_node("Armature").duplicate()
				ghost.get_node("Skeleton/Mesh").mesh = ghost.get_node("Skeleton/Mesh").mesh.duplicate()
				ghost.add_child(Globals.unit_lookup[unit_type].get_node("GhostHitbox").duplicate())
				ghost.transform.origin = new_building_position
				new_order.data.ghost = ghost
				new_order.update_order()
				unit.new_orders(new_order)
				return
		push_error("AI for team %s failed to find build location" % team.team_name)
	func _init(_team: Team):
		team = _team
	func process(delta: float):
		time += delta
		if time > update_time:
			time = 0.0
			
			var offensive_units = 0
			var num_factories = 0
			for unit in team.units:
				if unit.damage > 0.0 and unit.orders.size() < 1:
					offensive_units += 1
				if unit.unit_type == Globals.UnitType.Factory:
					num_factories += 1
			if team.queen.health < last_queen_health:
				current_mode = Modes.Defend
			elif team.blood < 100 and randf() > 0.5:
				current_mode = Modes.BloodEconomy
			elif team.enzymes < 1000:
				current_mode = Modes.EnzymeEconomy
			elif offensive_units < 25:
				current_mode = Modes.Production
			else:
				current_mode = Modes.Attack
			match current_mode:
				Modes.BloodEconomy:
					for unit in team.units:
						if unit.orders.size() < 1 and Globals.UnitType.Blood in unit.buildable_units:
							attempt_to_place_building(unit, Globals.UnitType.Blood)
							
				Modes.EnzymeEconomy:
					for unit in team.units:
						if unit.orders.size() < 1 and Globals.UnitType.Enzyme in unit.buildable_units:
							attempt_to_place_building(unit, Globals.UnitType.Enzyme)
				Modes.Production:
					for unit in team.units:
						if unit.orders.size() < 1:
							if (num_factories < 5 or randf() > 0.9) and Globals.UnitType.Factory in unit.buildable_units:
								attempt_to_place_building(unit, Globals.UnitType.Factory)
							elif Globals.UnitType.Bug in unit.buildable_units and randf() > 0.05:
								attempt_to_place_building(unit, Globals.UnitType.Bug)
							elif Globals.UnitType.Worker in unit.buildable_units:
								attempt_to_place_building(unit, Globals.UnitType.Worker)
				Modes.Attack:
					for target_team in Globals.main_node.surface.teams:
						if target_team != team and randf() <= 1.0 / (Globals.main_node.surface.teams.size() - 1):
							for unit in team.units:
								if unit.orders.size() < 1 and unit.unit_type == Globals.UnitType.Bug:
									var new_order = Order.new(OrderType.AttackUnit,Globals.main_node)
									new_order.data.target = target_team.queen
									new_order.update_order()
									unit.clear_orders()
									unit.new_orders(new_order)
				Modes.Defend:
					for unit in team.units:
						if unit.orders.size() < 1 and unit.damage > 0.0:
							var new_order = Order.new(OrderType.Move,Globals.main_node)
							new_order.data.target = team.queen.transform.origin
							new_order.update_order()
							unit.clear_orders()
							unit.new_orders(new_order)
			last_queen_health = team.queen.health
func _init():
	unit_scenes[UnitType.Bug] = load("res://Units/bug.tscn")
	unit_scenes[UnitType.Queen] = load("res://Units/bug_queen.tscn")
	unit_scenes[UnitType.Blood] = load("res://Units/Buildings/Economy/Hematoph/Hematoph.tscn")
	unit_scenes[UnitType.Enzyme] = load("res://Units/Buildings/Economy/EnzymeGland/EnzymeGland.tscn")
	unit_scenes[UnitType.Factory] = load("res://Units/Buildings/Construction/bug_factory.tscn")
	unit_scenes[UnitType.Worker] = load("res://Units/worker.tscn")
	print("Globals Ready")
	

func _process(_delta):
	if old_cursor_state != cursor_state:
		old_cursor_state = cursor_state
		match cursor_state:
			CursorState.Select:
				Input.set_custom_mouse_cursor(preload("res://Cursors/default.png"))
			CursorState.Attack:
				Input.set_custom_mouse_cursor(preload("res://Cursors/attack.png"))
			CursorState.Build:
				Input.set_custom_mouse_cursor(preload("res://Cursors/build.png"))





var colors = [Color("#000000"),Color("#00FF00"),Color("#0000FF"),Color("#FF0000"),Color("#01FFFE"),Color("#FFA6FE"),Color("#FFDB66"),Color("#006401"),Color("#010067"),Color("#95003A"),Color("#007DB5"),Color("#FF00F6"),Color("#FFEEE8"),Color("#774D00"),Color("#90FB92"),Color("#0076FF"),Color("#D5FF00"),Color("#FF937E"),Color("#6A826C"),Color("#FF029D"),Color("#FE8900"),Color("#7A4782"),Color("#7E2DD2"),Color("#85A900"),Color("#FF0056"),Color("#A42400"),Color("#00AE7E"),Color("#683D3B"),Color("#BDC6FF"),Color("#263400"),Color("#BDD393"),Color("#00B917"),Color("#9E008E"),Color("#001544"),Color("#C28C9F"),Color("#FF74A3"),Color("#01D0FF"),Color("#004754"),Color("#E56FFE"),Color("#788231"),Color("#0E4CA1"),Color("#91D0CB"),Color("#BE9970"),Color("#968AE8"),Color("#BB8800"),Color("#43002C"),Color("#DEFF74"),Color("#00FFC6"),Color("#FFE502"),Color("#620E00"),Color("#008F9C"),Color("#98FF52"),Color("#7544B1"),Color("#B500FF"),Color("#00FF78"),Color("#FF6E41"),Color("#005F39"),Color("#6B6882"),Color("#5FAD4E"),Color("#A75740"),Color("#A5FFD2"),Color("#FFB167"),Color("#009BFF"),Color("#E85EBE"),]
