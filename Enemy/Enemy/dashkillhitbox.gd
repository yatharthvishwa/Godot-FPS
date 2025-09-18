extends Area3D

@export var enemy_node_path: NodePath = NodePath("..") # default to parent
var enemy_node: Node = null

func _ready():
	if enemy_node_path != NodePath(""):
		enemy_node = get_node_or_null(enemy_node_path)
	else:
		enemy_node = get_parent()

# forwarder method so player can call area.slidekilled()
func dashkilled():
	if enemy_node and enemy_node.has_method("dashkilled"):
		enemy_node.dashkilled()
