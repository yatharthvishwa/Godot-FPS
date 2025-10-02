class_name Enemy

extends CharacterBody3D

enum states
{
	ENEMYIDLE,ENEMYRUN,ENEMYPUNCH
}
var currentState

@onready var move_state_machine = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var player = get_tree().get_first_node_in_group("player")
@onready var skin = get_node('skin')

@export var SPEED = 10.0
@export var rotation_speed_towards_player = 10.0
@export var notice_radius = 30.0
@export var attack_radius = 2.2


func move_to_player(delta):
	var gravity = -10.0 * delta
	if position.distance_to(player.position) < notice_radius:
		var target_dir = (player.position - position).normalized()
		var target_vec2 = Vector2(target_dir.x , target_dir.z)
		var target_angle = -target_vec2.angle() + PI/2 
		rotation.y = rotate_toward(rotation.y, target_angle, rotation_speed_towards_player * delta )
		if position.distance_to(player.position) > attack_radius: #if position is greater than attack radius then move towards player
			velocity = Vector3(target_vec2.x ,gravity, target_vec2.y) * SPEED
			move_state_machine.travel('Run')
			currentState == states.ENEMYRUN
		#else:
			#velocity = Vector3.ZERO
			#move_state_machine.travel('Idle')
			#currentState == states.ENEMYIDLE
	
	move_and_slide()
