extends Node3D

class_name sword

signal enemydeath()

@onready var animation_player = $AnimationPlayer
@onready var MeleeHitbox = $MeleeHitbox


@onready var enemyanimationtree = $AnimationTree


var damage = 10.0

var can_slash = false
var enemies_in_range = []


func _process(delta):
	
	melee()
	#if Input.is_action_just_pressed("shoot") and not animation_player.is_playing():
		#animation_player.play("slash")
		##swooshsound play
		#can_slash = false
		#if !enemies_in_range.is_empty():
			#for e in enemies_in_range:
				#e.hit(damage)

func melee():
	if Input.is_action_just_pressed("shoot"):
		if not animation_player.is_playing():
			animation_player.play("slashforward")
			animation_player.queue("slashbackward")
		
		#if animation_player.current_animation == "slashforward":
			#for body in MeleeHitbox.get_overlapping_bodies():
				#if body.is_in_group("enemy"):
					#print("thislie")
					#enemydeath.emit()
					#enemyanimationtree.set("parameters/conditions/death", true)
		



#func _on_area_3d_body_entered(body):
	#if body.is_in_group("enemy") and not enemies_in_range.has(body):
		#enemies_in_range.append(body) #.append(body): Adds the enemy body to the tracking array


#
#func _on_area_3d_body_exited(body):
	#if enemies_in_range.has(body):
		#enemies_in_range.erase(body) #.append(body): Adds the enemy body to the tracking array

#
#func _on_animation_player_animation_finished(anim_name):
	#if anim_name == "slash":
		#can_slash = true



#func _on_melee_hitbox_area_entered(area):
	#
	#if animation_player.current_animation == "slashforward":
		#for body in MeleeHitbox.get_overlapping_bodies():
			#if body.is_in_group("enemy"):
				#body.enemyanimationtree.set("parameters/conditions/death", true)




 
#func _on_melee_hitbox_body_entered(body):
	#if body.is_in_group("enemy") and Input.is_action_just_pressed("shoot"):
		#print("hit")
