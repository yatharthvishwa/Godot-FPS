extends Node

var kill_count : int = 0

#var playergroupintree = get_tree().get_nodes_in_group("player")
func _ready():
	pass
	
func add_kill():
	kill_count += 1
	killcounteffect()
	print("Kills: ", kill_count)


func killcounteffect():
	if kill_count >= 1:
		print("done")
		var playergroupintree = get_tree().get_nodes_in_group("player")
		if playergroupintree.size() > 0:
			var playernode = playergroupintree[0]
			playernode.killeffect()
