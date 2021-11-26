extends TabContainer

var unit_data 

func _ready():
	pass

func _process(_delta):
	if Globals.cursor_state == Globals.CursorState.Build:
		current_tab = 1
	else:
		current_tab = 0


func tab_changed(tab):
	if tab == 0:
		Globals.cursor_state = Globals.CursorState.Select
	else:
		Globals.cursor_state = Globals.CursorState.Build
		for child in $Buildings.get_children():
			child.queue_free()

		var buildable_units = []
		for unit in Globals.player_team.units:
			if unit.is_selected:
				for buildable_unit in unit.buildable_units:
					if not buildable_unit in buildable_units:
						buildable_units.append(buildable_unit)
		for unit_type in buildable_units:
			var new_icon = preload("res://UI/BuildingIcon.tscn").instance()
			new_icon.unit_type = unit_type
			$Buildings.add_child(new_icon)
		for _i in range((4*4) - buildable_units.size()):
			var blank_icon = Control.new()
			blank_icon.size_flags_horizontal = SIZE_EXPAND_FILL
			blank_icon.size_flags_vertical = SIZE_EXPAND_FILL
			$Buildings.add_child(blank_icon)
