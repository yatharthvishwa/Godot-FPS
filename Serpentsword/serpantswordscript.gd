extends Node3D

@onready var animation_player = $AnimationPlayer

var damage = 10.0

var can_slash = false
var enemies_in_range = []


func _process(delta):
	if Input.is_action_just_pressed("shoot") and can_slash and not animation_player.is_playing():
		#animation_player.play("slash")
		#swooshsound play
		can_slash = false
		if !enemies_in_range.is_empty():
			for e in enemies_in_range:
				e.hit(damage)




func _on_area_3d_body_entered(body):
	if body.is_in_group("enemy") and not enemies_in_range.has(body):
		enemies_in_range.append(body) #.append(body): Adds the enemy body to the tracking array



func _on_area_3d_body_exited(body):
	if enemies_in_range.has(body):
		enemies_in_range.erase(body) #.append(body): Adds the enemy body to the tracking array


#func _on_animation_player_animation_finished(anim_name):
	#if anim_name == "slash":
		#can_slash = true
