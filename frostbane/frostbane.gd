extends CharacterBody3D


@onready var player = get_tree().get_first_node_in_group("player")
@onready var frostbane_move_state_machine = $AnimationTree.get("parameters/FrostMoveStateMachine/playback")
@onready var attack_animationoneshot = $AnimationTree.get_tree_root().get_node('AttackAnimation') #this is getting the attack animation and then we'll change the animation itself for oneshot
@export var SPEED = 10.0
@export var rotation_speed_towards_player = 10.0
@export var notice_radius = 30.0
@export var attack_radius = 5.0

var rng = RandomNumberGenerator.new()

const attacks = {
	'jumpattack':"frost_jump",
	'spinslash':"frost_reverse_slash",
	'slam':"frost_slam",
	'downslash':"frost_down_slash",
	'slash':"frost_slash"
}

func _ready():
	var playergroupintree = get_tree().get_nodes_in_group("player")
	if playergroupintree.size() > 0:
		var playernode = playergroupintree[0]

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
	var chosen_attack = "spinslash"
	if rng.randi() %2 == 0:
		chosen_attack = "downslash"
	attack_animationoneshot.animation = attacks[chosen_attack]
	$AnimationTree.set("parameters/FrostAttackOneShot/request", true)
	isattackfiring = true
	if chosen_attack == "downslash":
		print("timercreated")
		await get_tree().create_timer(2.7).timeout
		isattackfiring = false
	elif chosen_attack == "spinslash":
		await get_tree().create_timer(2.8).timeout
		isattackfiring = false
func rangeattack():
	var chosen_attack = "slam"
	if rng.randi() %2 == 0:
		chosen_attack = "jumpattack"
	attack_animationoneshot.animation = attacks[chosen_attack]
	$AnimationTree.set("parameters/FrostAttackOneShot/request", true)
	isattackfiring = true
	if chosen_attack == "slam":
		await get_tree().create_timer(2.46).timeout

		isattackfiring = false
	elif chosen_attack == "jumpattack":
		await get_tree().create_timer(2.46).timeout
		isattackfiring = false

@onready var enemycollision_shape_3d = $CollisionShape3D
@onready var mutant_mesh = $frostbane2/Armature/Skeleton3D/MutantMesh

@onready var debris = $frostparticles/debris
@onready var blood = $frostparticles/blood


var frostmax_health = 100
var frostcurrent_health: int = frostmax_health
var is_dead = false
func dashkilled():
	if is_dead:
		return
	attack_animationoneshot.animation = "frost_hit"
	$AnimationTree.set("parameters/FrostAttackOneShot/request", true)
	debris.emitting = true
	blood.emitting = true
	frostcurrent_health -= 10
	
	if frostcurrent_health <= 0:
		is_dead = true
		frostdead()

	
func frostdead():
	frostbane_move_state_machine.travel('frost_death')
	velocity = Vector3.ZERO
	enemycollision_shape_3d.disabled = true
	set_physics_process(false)
	set_process(false)
	$AnimationTree.set("parameters/FrostAttackOneShot/abort", true)
	$AnimationTree.set("parameters/FrostAttackOneShot/active", false)


func _on_slash_timer_timeout():
	if !isattackfiring and !is_dead:
		if position.distance_to(player.position) < attack_radius:
			frostslash()
		else:
			rangeattack()
			
