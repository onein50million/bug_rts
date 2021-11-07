extends Unit

func _ready():
	speed = 0.1

func _process(delta):
	if randf() > 0.99:
		surface.spawn_bug(transform.origin, UnitType.Bug)
