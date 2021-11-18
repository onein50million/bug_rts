extends MeshInstance

var order_type
var order_data = {}

func _ready():
	pass



func _process(_delta):
	match order_type:
		Globals.OrderType.AttackUnit:
			if is_instance_valid(order_data.target):
				transform.origin = order_data.target.transform.origin

