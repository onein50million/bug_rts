extends Building

func _init():
	self.unit_type = Globals.UnitType.Factory
	self.pretty_name = "Bug Factory"
	self.buildable_units.append_array([Globals.UnitType.Bug,])
	
	self.enzyme_output = 10.0
	self.blood_output = 1.0
func _ready():
	pass
