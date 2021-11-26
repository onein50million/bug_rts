extends Unit

func _init():
	self.unit_type = Globals.UnitType.Worker
	self.speed *= 1.2
	self.pretty_name = "Worker"
	self.damage = 1.0
	
	self.enzyme_output = 10.0
	self.blood_output = 1.0
	self.buildable_units.append_array([Globals.UnitType.Factory,Globals.UnitType.Blood,Globals.UnitType.Enzyme])
