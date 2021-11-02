extends StaticBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func mix(x:float, y:float, a:float):
	return x *(1.0-a) + y * a
	
func fract_vec2(x: Vector2):
	return x - Vector2(floor(x.x), floor(x.y))

func fract_float(x: float):
	return x - floor(x)

func hash(p: Vector2) -> float:
	return fract_float(sin((p*17.17).dot(Vector2(14.91,67.31))) * 4791.9511)
	

func vec_floor(x: Vector2):
	return Vector2(floor(x.x), floor(x.y))

func noise(x: Vector2) -> float:
	var p = vec_floor(x)
	var f = fract_vec2(x)
	f = f * f * (Vector2(3.0,3.0) - 2.0 * f)
	var a = Vector2(1.0, 0.0)
	return mix(mix(hash(p + Vector2(a.y,a.y)), hash(p + Vector2(a.x,a.y)), f.x),mix(hash(p + Vector2(a.y,a.x)), hash(p + Vector2(a.x,a.x)), f.x), f.y)

# Called when the node enters the scene tree for the first time.
func _ready():
	var heightmap:HeightMapShape = $CollisionShape.shape
	for x_index in range(heightmap.map_width):
		for y_index in range(heightmap.map_depth):
			var x = float(x_index) - float(heightmap.map_width) * 0.5
			var y = float(y_index) - float(heightmap.map_depth) *  0.5

			var local_position = Vector3(x,y,0.0)
			var world_position = transform * local_position

			var height = noise(Vector2(world_position.x,world_position.y)*0.1)* 0.000000001
			print(height)
			heightmap.map_data[x_index + y_index * heightmap.map_width] = height 


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
