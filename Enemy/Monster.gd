extends CharacterBody3D

class_name enemy

var player = null
var health = 15.0

const SPEED = 15.0
const PUNCH_RANGE = 5.0
const DAMAGE = 2.0

enum State {IDLE, RUN, PUNCH, DEATH}
var current_state = State.RUN
var state_machine


@export var player_path : NodePath

@onready var player_character = $"../../PlayerCharacter"
@onready var hitbox = $hitbox
@onready var hitboxcollisionshape = $hitbox/CollisionShape3D

@onready var animation_tree = $AnimationTree
@onready var collision_shape_3d = $CollisionShape3D
@onready var navigation_agent_3d = $NavigationAgent3D

func _ready() -> void:
	
	player = get_node(player_path)
	state_machine = animation_tree.get("parameters/playback")
	animation_tree.active = true
	set_state(State.IDLE)  # Start in sprint state
	
func _physics_process(delta: float) -> void:
	# Process current state
	match current_state:
		State.IDLE:
			process_idle(delta)
		State.RUN:
			process_run(delta)
		State.PUNCH:
			process_punch(delta)
		State.DEATH:
			pass
	
	move_and_slide()

# State transition function
func set_state(new_state: State):
	if current_state != new_state:
		exit_state(current_state)
		current_state = new_state
		enter_state(new_state)

func enter_state(state: State):
	match state:
		State.IDLE:
			animation_tree.set("parameters/conditions/idle", true)
		State.RUN:
			#animation_tree.set("parameters/conditions/run", true)
			animation_tree.set("parameters/conditions/punch", false)
		State.PUNCH:
			#animation_tree.set("parameters/conditions/run", false)
			animation_tree.set("parameters/conditions/punch", true)
		#State.DEATH:
			#animation_tree.set("parameters/conditions/death", true)

func exit_state(state: State):
	# Clean up previous state if needed
	match state:
		State.RUN:
			animation_tree.set("parameters/conditions/run", false)
			animation_tree.set("parameters/conditions/punch", true)
		State.PUNCH:
			animation_tree.set("parameters/conditions/run", true)
			animation_tree.set("parameters/conditions/punch", false)
		State.DEATH:
			pass

func process_run(delta: float):
	# Update navigation target
	navigation_agent_3d.set_target_position(player.global_transform.origin)
	var next_navigation_point = navigation_agent_3d.get_next_path_position()
	
	# Move towards player
	velocity = (next_navigation_point - global_transform.origin).normalized() * SPEED
	
	# Look at player (only on Y axis)
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	
	# Check for state transitions
	if target_in_range():
		set_state(State.PUNCH)
	elif !target_in_range():
		set_state(State.RUN)

func process_punch(delta: float):
	velocity = Vector3.ZERO
	
	if target_in_range():
		set_state(State.PUNCH)
		#player_character.velocity.y = 20.0 #this line is kinda problematic
	# Check if player moved out of range
	elif !target_in_range():
		set_state(State.RUN)
	
	
	# Look at player while attacking
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	
	
func process_idle(delta: float):
	set_state(State.IDLE)
	if target_in_range():
		set_state(State.RUN)
	else: set_state(State.IDLE)

func target_in_range():
	return global_position.distance_to(player.global_position) < PUNCH_RANGE




#func _on_hitbox_area_entered(area):
	#for body in hitbox.get_overlapping_bodies():
		#if body.is_in_group("sword"):
			#animation_tree.set("parameters/conditions/death", true)
	 ## Replace with function body.


	
		


#func _on_sword_enemydeath():
	#var anim_tree = get_node("AnimationTree")
	#anim_tree.set("parameters/conditions/death", true)
	#velocity = Vector3.ZERO
	#collision_shape_3d.disabled = true
	#set_physics_process(false)
	#set_process(false)


# NEW: Centralized death function
func die():
	#if current_state == State.DEATH:
		#return  # Already dead, don't process again
	#
	set_state(State.DEATH)
	animation_tree.set("parameters/conditions/death", true)
	velocity = Vector3.ZERO
	collision_shape_3d.disabled = true
	hitboxcollisionshape.disabled = true
	set_physics_process(false)
	set_process(false)



func _on_hitbox_area_entered(area):
	# check if the area that entered is a sword/weapon
	if area.is_in_group("sword") and Input.is_action_just_pressed("shoot") :
		die()
		


func _on_hitbox_area_exited(area):
	# check if the area that entered is a sword/weapon
	if area.is_in_group("sword") and Input.is_action_just_pressed("shoot") :
		
		die()
