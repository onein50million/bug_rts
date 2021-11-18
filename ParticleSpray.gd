extends Particles

var time = 0.0
var base_basis
func _ready():
	base_basis = transform.basis

func _process(delta):
	time += delta
	transform.basis = base_basis * Basis(Quat(Vector3(0.0,sin(time*10.0)*(PI/16.0),0.0)))
