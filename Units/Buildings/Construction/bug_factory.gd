extends Building

func _init():
	self.unit_type = Globals.UnitType.Factory
	self.pretty_name = "Bug Factory"
	self.buildable_units.append_array([Globals.UnitType.Bug,Globals.UnitType.Worker])
	
	self.start_animation_name = "liftarms"
	self.build_animation_name = "ArmsWork"
	
	self.max_health = 100.0
	self.blood_cost = 50.0
	self.enzyme_cost = blood_cost * 10.0
	self.enzyme_output = 10.0
	self.blood_output = 1.0
func _ready():
	pass
