extends Node3D

@onready var monster = preload("res://Enemy/Enemy/monster_enemy.tscn")

func _on_timer_timeout():
	var monsterspawn = monster.instantiate()
	monsterspawn.position = position
	get_parent().add_child(monsterspawn)
