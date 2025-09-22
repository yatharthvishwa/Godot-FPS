extends Node3D

@onready var monster = preload("res://Enemy/Enemy/monster_enemy.tscn")

func _on_timer_timeout():
	var num_to_spawn = randi_range(1, 5)
	for i in range(num_to_spawn):
		var monsterspawn = monster.instantiate()
		
		monsterspawn.position = position + Vector3(
			randf_range(-5, 5), 
			0, 
			randf_range(-5, 5)
		)
		
		get_parent().add_child(monsterspawn)
