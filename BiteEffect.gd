extends Node2D

var world_position: Vector3
var camera: Camera

func _ready():
	$Upper.emitting = true
	$Lower.emitting = true

func _process(_delta):
	position = camera.unproject_position(world_position)
	if $Upper.emitting == false:
		queue_free()
