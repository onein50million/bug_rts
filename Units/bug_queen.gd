extends Unit

func _init():
	self.unit_type = Globals.UnitType.Queen
	
	self.speed = 0.02
	self.max_health = 300.0
	self.damage = 10.0
	self.attack_time = 0.1
	self.build_range = 0.1
	self.enzyme_production = 50.0
	self.blood_production = 5.0
	self.enzyme_output = 100.0
	self.blood_output = 10.0
	self.num_guts = 100
	self.gut_velocity = 2.0
	
	self.smoothness = 0.5
	
	self.buildable_units.append_array([Globals.UnitType.Factory,Globals.UnitType.Blood,Globals.UnitType.Enzyme])
	
	self.pretty_name = "Queen"

func die():
	if self.last_damage_source_team != null:
		self.last_damage_source_team.queen_kills += 1
	.die()

