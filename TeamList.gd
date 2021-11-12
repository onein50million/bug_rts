extends Tree

class TeamTreeItem:
	var tree_item: TreeItem
	var team: Globals.Team
	
	func _init(_team:Globals.Team, _tree_item: TreeItem):
		team = _team
		tree_item = _tree_item

var items = []

func new_item(team: Globals.Team):
	items.append(TeamTreeItem.new(team, create_item()))

func _ready():
	set_column_expand(1, false)
	set_column_min_width(1, 24)
	


func _process(_delta):
	for item in items:
		item.tree_item.set_text(0,"%s" % item.team.team_name)
		item.tree_item.set_icon(1, preload("res://UI/Icons/BugIcon.png"))
		item.tree_item.set_icon_modulate(1, item.team.color)
#		item.tree_item.set_icon_max_width(1, 200.0)
		item.tree_item.set_text(2,"%d" % item.team.queen.health if is_instance_valid(item.team.queen) else "DEAD X.X")
		item.tree_item.set_text(3,"%d" % item.team.bug_kills)
		item.tree_item.set_text(4,"%d" % item.team.queen_kills)



	
