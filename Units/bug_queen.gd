extends Unit

func _init():
	self.unit_type = Globals.UnitType.Queen
	
	self.speed = 0.1
	self.max_health = 500.0
	self.damage = 100.0
	self.attack_time = 0.1

	self.enzyme_production = 50.0
	self.blood_production = 5.0
	self.enzyme_output = 100.0
	self.blood_output = 10.0
	
	self.smoothness = 0.99
	
	self.buildable_units.append_array([Globals.UnitType.Factory,Globals.UnitType.Blood,Globals.UnitType.Enzyme])
	
	self.pretty_name = "Queen"

func die():
	if self.last_damage_source_team != null:
		self.last_damage_source_team.queen_kills += 1
	.die()

