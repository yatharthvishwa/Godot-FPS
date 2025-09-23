extends Node3D

var audioplaying = false
@onready var audio_stream_player = $AudioStreamPlayer
func _ready():
	add_to_group("world")   # So enemies can find this script

func on_enemy_dashkilled(enemy: Node):
	if !audioplaying:
		print("Enemy dashkilled:", enemy.name)
		audio_stream_player.play()  
		audioplaying = true
