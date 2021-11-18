extends Building

func _init():
	self.blood_production = 1.0
	self.unit_type = Globals.UnitType.Blood
	self.pretty_name = "Hematoph"


func _ready():
	$AnimationPlayer.play("Pulse")
	$AnimationPlayer.get_animation("Pulse").loop = true
	$AnimationPlayer.seek(rand_range(0.0,2.0))
