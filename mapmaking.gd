extends Node3D

@onready var ctrl = $ctrl
@onready var rightclick = $rightclick
@onready var shift = $SHIFT

var playernode: Node = null

func _ready():
	
	var playergroupintree = get_tree().get_nodes_in_group("player")
	if playergroupintree.size() > 0:
		playernode = playergroupintree[0]

func _on_area_3d_body_entered(_body):
	ctrl.visible = true


func _on_area_3d_body_exited(_body):
	ctrl.visible = false


func _on_dashkillareacontrol_body_entered(_body):
	rightclick.visible = true


func _on_dashkillareacontrol_body_exited(_body):
	rightclick.visible = false


func _on_sprintareacontrol_body_entered(body):
	shift.visible = true


func _on_sprintareacontrol_body_exited(body):
	shift.visible = false


@onready var trapdoor = $trapdoor

var trapdoor_tween: Tween
var open_y = 51.633
var closed_y = 37.268

func _on_trapdoorarea_body_entered(body):
	if trapdoor_tween and trapdoor_tween.is_running():
		trapdoor_tween.kill() # stop any existing tween
	trapdoor_tween = get_tree().create_tween()
	trapdoor_tween.tween_property(trapdoor, "position:y", open_y, 1.0)

func _on_trapdoorarea_body_exited(body):
	if trapdoor_tween and trapdoor_tween.is_running():
		trapdoor_tween.kill()
	trapdoor_tween = get_tree().create_tween()
	trapdoor_tween.tween_property(trapdoor, "position:y", closed_y, 1.0)


func _on_lava_area_body_entered(body):
	if body.is_in_group("player"):
		playernode.playerdead()
