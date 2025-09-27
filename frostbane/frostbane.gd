extends CharacterBody3D


@onready var player = get_tree().get_first_node_in_group("player")
@onready var frostbane_move_state_machine = $AnimationTree.get("parameters/FrostMoveStateMachine/playback")
@onready var attack_animationoneshot = $AnimationTree.get_tree_root().get_node('AttackAnimation') #this is getting the attack animation and then we'll change the animation itself for oneshot
@export var SPEED = 10.0
@export var rotation_speed_towards_player = 10.0
@export var notice_radius = 30.0
@export var attack_radius = 5.0

const attacks = {
	'jumpattack':"frost_jump",
	'spinslash':"frost_reverse_slash",
	'slam':"frost_slam",
	'downslash':"frost_down_slash"
}

func _physics_process(delta):
	move_to_player(delta)


func move_to_player(delta):
	var gravity = -10.0 * delta
	if position.distance_to(player.position) < notice_radius:
		var target_dir = (player.position - position).normalized()
		var target_vec2 = Vector2(target_dir.x , target_dir.z)
		var target_angle = -target_vec2.angle() + PI/2 
		rotation.y = rotate_toward(rotation.y, target_angle, rotation_speed_towards_player * delta )
		if position.distance_to(player.position) > attack_radius: #if position is greater than attack radius then move towards player
			velocity = Vector3(target_vec2.x ,gravity, target_vec2.y) * SPEED
			frostbane_move_state_machine.travel('FrostRun')
		else:
			velocity = Vector3.ZERO
			frostbane_move_state_machine.travel('FrostIdle')
	
	move_and_slide()

@onready var frostbane_attack_state_machine = $AnimationTree.get("parameters/FrostAttackStateMachine/playback")
var isattackfiring = false
func frostslash():
	attack_animationoneshot.animation = attacks['downslash']
	$AnimationTree.set("parameters/FrostAttackOneShot/request", true)
func rangeattack():
	attack_animationoneshot.animation = attacks['slam']
	$AnimationTree.set("parameters/FrostAttackOneShot/request", true)
	isattackfiring = true
	velocity.y = -20.0
	await get_tree().create_timer(2.46).timeout
	isattackfiring = false

func _on_slash_timer_timeout():
	if position.distance_to(player.position) < attack_radius:
		frostbane_move_state_machine.travel('FrostRun')
		frostslash()
	else:
		if !isattackfiring:
			rangeattack()
