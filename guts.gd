extends RigidBody

var time = 0.0
var lifetime = 10.0
func _process(delta):
	time += delta
	if time > lifetime:
		queue_free()
