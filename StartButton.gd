extends Button

var loader: ResourceInteractiveLoader = null

onready var load_thread: Thread = Thread.new()



func _ready():
	pass

func finish_thread():
	load_thread.wait_to_finish()

func poll_loader(_garbage):
	var _output = loader.poll()
	call_deferred("finish_thread")

func _process(_delta):
	
	if loader != null:
		if not load_thread.is_active() and loader.get_stage() < loader.get_stage_count() - 1:
#			print(float(loader.get_stage()) / float(loader.get_stage_count() - 1))
			load_thread.start(self, "poll_loader")
		if not load_thread.is_active() and loader.poll() == ERR_FILE_EOF:
			var game_scene = loader.get_resource().instance()
			get_tree().get_root().add_child(game_scene)
			get_node("/root/TextureRect").queue_free()

	
func _pressed():
	randomize()
	Globals.player_team_color = get_parent().get_node("GridContainer/TeamColorPicker").color
	Globals.player_team_name = get_parent().get_node("GridContainer/TeamNameEdit").text
	Globals.enemy_team_count = get_parent().get_node("GridContainer/EnemyTeamCountSelector").value
	Globals.spectate = get_parent().get_node("GridContainer/SpectateBox").pressed
	text = "Loading..."
	
	loader = ResourceLoader.load_interactive("res://Main.tscn")
	disabled = true
	
