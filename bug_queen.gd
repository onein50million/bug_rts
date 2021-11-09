extends Unit

func _init():
	speed = 0.1
	unit_type = Globals.UnitType.Queen

func die():
	last_damage_source_team.queen_kills += 1
	.die()


func _process(_delta):	
	if randf() > 0.99 and team.units.size() < 50:
		surface.spawn_bug(transform.origin, Globals.UnitType.Bug, team)
