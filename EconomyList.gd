extends GridContainer

var last_blood_amount = 0.0
var last_enzyme_amount = 0.0

func _ready():
	pass

func _process(delta):
	$BloodAmount.text = "%d" % Globals.player_team.blood
	$EnzymeAmount.text = "%d" % Globals.player_team.enzymes
	
	var delta_blood = Globals.player_team.blood - last_blood_amount
	last_blood_amount = Globals.player_team.blood
	var delta_enzyme = Globals.player_team.enzymes - last_enzyme_amount
	last_enzyme_amount = Globals.player_team.enzymes
	
	$BloodIncome.text = "%d" % ((1.0/max(delta,0.0000001))*delta_blood)
	$EnzymeIncome.text = "%d" % ((1.0/max(delta,0.0000001))*delta_enzyme)
