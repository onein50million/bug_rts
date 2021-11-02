extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var car_path: NodePath

onready var noise = OpenSimplexNoise.new()


func get_height(local_position: Vector3, transform_matrix: Transform) -> float:
	var world_position = transform_matrix * local_position
	var height = noise.get_noise_2d(world_position.x, world_position.z)*10.0
	return height
	
func generate_terrain(transform_matrix: Transform):
	
	var surface_tool = SurfaceTool.new()
	
	surface_tool.create_from($MeshInstance.mesh,0)
	
	var array_plane = surface_tool.commit()
	var mesh_tool = MeshDataTool.new()
	mesh_tool.create_from_surface(array_plane,0)
	
	for i in range(mesh_tool.get_vertex_count()):
		var local_position = mesh_tool.get_vertex(i)
		
		mesh_tool.set_vertex(i, Vector3(local_position.x, get_height(local_position,transform_matrix), local_position.z))
	
	array_plane.surface_remove(0)
	
	mesh_tool.commit_to_surface(array_plane)
	
	$MeshInstance.mesh = array_plane
	
	
	var heightmap:HeightMapShape = $terrain_body/CollisionShape.shape.duplicate()
	for x_index in range(heightmap.map_width):
		for z_index in range(heightmap.map_depth):
			var x = float(x_index) - float(heightmap.map_width) * 0.5
			var z = float(z_index) - float(heightmap.map_depth) * 0.5
			
			var local_position = Vector3(x,0,z)
			heightmap.map_data[x_index + z_index * heightmap.map_width] = get_height(local_position,transform_matrix)
	
	$terrain_body/CollisionShape.call_deferred("set_shape",heightmap)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	generate_terrain(transform)

	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var car_position = get_node(car_path).get_node("body").transform.origin
	var terrain_position = transform.origin
	terrain_position.y = 0
	car_position.y = 0
#	if car_position.distance_to(terrain_position) > 10:
#		transform.origin.x = car_position.x
#		transform.origin.z = car_position.z
#		generate_terrain(transform)
