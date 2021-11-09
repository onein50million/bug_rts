extends Control

export var legend = false

var team: Globals.Team

func _ready():
	if not legend:
		$TeamName.text = "%s" % team.team_name
		$TeamColor.color = team.color
	else:
		set_process(false)

func _process(_delta):
	$QueenHealth.text = "%d" % team.queen.health if is_instance_valid(team.queen) else "DEAD X.X"
	$BugKills.text = "%d" % team.bug_kills
	$QueenKills.text = "%d" % team.queen_kills
