extends CharacterBody3D

class_name enemy

var player = null
var health = 15.0

const SPEED = 15.0
const ATTACK_RANGE = 2.0
const DAMAGE = 2.0

enum State {SPRINT, ATTACK}
var current_state = State.SPRINT
var state_machine

@export var player_path : NodePath

@onready var player_character = $"../../PlayerCharacter"

@onready var animation_tree = $AnimationTree
@onready var collision_shape_3d = $CollisionShape3D
@onready var navigation_agent_3d = $NavigationAgent3D

func _ready() -> void:
	player = get_node(player_path)
	state_machine = animation_tree.get("parameters/playback")
	animation_tree.active = true
	set_state(State.SPRINT)  # Start in sprint state
	
func _physics_process(delta: float) -> void:
	# Process current state
	match current_state:
		State.SPRINT:
			process_sprint(delta)
		State.ATTACK:
			process_attack(delta)
	
	move_and_slide()

# State transition function
func set_state(new_state: State):
	if current_state != new_state:
		exit_state(current_state)
		current_state = new_state
		enter_state(new_state)

func enter_state(state: State):
	match state:
		State.SPRINT:
			animation_tree.set("parameters/conditions/Sprint", true)
			animation_tree.set("parameters/conditions/Attack", false)
		State.ATTACK:
			animation_tree.set("parameters/conditions/Sprint", false)
			animation_tree.set("parameters/conditions/Attack", true)

func exit_state(state: State):
	# Clean up previous state if needed
	pass


func process_sprint(delta: float):
	# Update navigation target
	navigation_agent_3d.set_target_position(player.global_transform.origin)
	var next_navigation_point = navigation_agent_3d.get_next_path_position()
	
	# Move towards player
	velocity = (next_navigation_point - global_transform.origin).normalized() * SPEED
	
	# Look at player (only on Y axis)
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	
	# Check for state transitions
	if target_in_range():
		set_state(State.ATTACK)
	elif !target_in_range():
		set_state(State.SPRINT)

func process_attack(delta: float):
	velocity = Vector3.ZERO
	
	if target_in_range():
		player_character.velocity.y = 20.0
	
	# Look at player while attacking
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	
	# Check if player moved out of range
	if !target_in_range():
		set_state(State.SPRINT)




func target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
