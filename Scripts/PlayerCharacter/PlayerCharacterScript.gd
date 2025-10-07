extends CharacterBody3D

#class name #DO NOT REMOVE THIS COMMENT, IT MAKES THE ENTIRE GAME CRASH
class_name PlayerCharacter

@onready var animation_state_machine = $CameraHolder/Camera3D/FirstpersonRig/PlayerAnimationTree.get("parameters/AnimationStateMachine/playback")

#states variables
enum states
{
	IDLE, WALK, RUN, CROUCH, SLIDE, JUMP, INAIR, LANDING
}
var currentState 

var landing_timer : float = 0.3
var landing_duration: float = 0.3

#audio ref
@onready var walk = $walk
@onready var run = $run
@onready var slide = $slide
@onready var falling = $falling
@onready var jump_audio = $jump

#move variables
@export_group("move variables")
var currentSpeed : float
var desiredMoveSpeed : float 
@export var desiredMoveSpeedCurve : Curve
@export var maxSpeed : float 
@export var walkSpeed : float
@export var runSpeed : float
@export var crouchSpeed : float
var slideSpeed : float
@export var slideSpeedAddon : float 
@export var dashSpeed : float 
var moveAcceleration : float
@export var walkAcceleration : float
@export var runAcceleration : float 
@export var crouchAcceleration : float 
var moveDecceleration : float
@export var walkDecceleration : float
@export var runDecceleration : float 
@export var crouchDecceleration : float 
@export var inAirMoveSpeedCurve : Curve

#movement variables
@export_group("movement variables")
var inputDirection : Vector2 
var moveDirection : Vector3 
@export var hitGroundCooldown : float #amount of time the character keep his accumulated speed before losing it (while being on ground)
var hitGroundCooldownRef : float 
var lastFramePosition : Vector3 
var floorAngle #angle of the floor the character is on 
var slopeAngle #angle of the slope the character is on
var canInput : bool 

#jump variables
@export_group("jump variables")
@export var jumpHeight : float
@export var jumpTimeToPeak : float
@export var jumpTimeToFall : float
@onready var jumpVelocity : float = (2.0 * jumpHeight) / jumpTimeToPeak
@export var jumpCooldown : float
@export var nbJumpsInAirAllowed : int 
var nbJumpsInAirAllowedRef : int 


#slide variables
@export_group("slide variables")
@export var slideTime : float
@export var slideTimeRef : float 
var slideVector : Vector2 = Vector2.ZERO #slide direction
var startSlideInAir : bool
@export var timeBeforeCanSlideAgain : float 
var timeBeforeCanSlideAgainRef : float 
@export var maxSlopeAngle : float #max angle value where the side time duration is applied


#gravity variables
@export_group("gravity variables")
@onready var jumpGravity : float = (-2.0 * jumpHeight) / (jumpTimeToPeak * jumpTimeToPeak)
@onready var fallGravity : float = (-2.0 * jumpHeight) / (jumpTimeToFall * jumpTimeToFall)

#references variables
@onready var cameraHolder = $CameraHolder
@onready var standHitbox = $standingHitbox
@onready var crouchHitbox = $crouchingHitbox
@onready var ceilingCheck = $Raycasts/CeilingCheck
@onready var floorCheck = $Raycasts/FloorCheck
@onready var mesh = $MeshInstance3D
@onready var player_animation_tree = $CameraHolder/Camera3D/FirstpersonRig/PlayerAnimationTree


func _ready():
	
	
	#set the start move speed
	currentSpeed = walkSpeed
	moveAcceleration = walkAcceleration
	moveDecceleration = walkDecceleration
	
	#set the values refenrencials for the needed variables
	desiredMoveSpeed = currentSpeed 
	nbJumpsInAirAllowedRef = nbJumpsInAirAllowed
	hitGroundCooldownRef = hitGroundCooldown
	slideTimeRef = slideTime
	timeBeforeCanSlideAgainRef = timeBeforeCanSlideAgain
	canInput = true
	
	#disable the crouch hitbox, enable is standing one
	if !crouchHitbox.disabled: crouchHitbox.disabled = true 
	if standHitbox.disabled: standHitbox.disabled = false
	
	#set the raycasts
	if !ceilingCheck.enabled: ceilingCheck.enabled = true
	if !floorCheck.enabled: floorCheck.enabled = true
	
@onready var speed_value = $"SPEED VALUE"


func _process(_delta):
	#the behaviours that is preferable to check every "visual" frame
	speed_value.text = "%.1f" % desiredMoveSpeed
	#killeffect()
	showdashkillavailable()
	
	slidekill()
	
	inputManagement()
	
	#print(current_health)
	
func _physics_process(delta):
	
	wallrun(delta)
	
	applyslam(delta)
	
	applies(delta)
	
	move(delta)
	
	animationchange()
	
	attack()
	
	
	audiochanges()
	
	checklanding(delta)
	
	move_and_slide()

func inputManagement():
	#for each state, check the possibles actions available
	#This allow to have a good control of the controller behaviour, because you can easely check the actions possibls, 
	#add or remove some, and it prevent certain actions from being played when they shouldn't be
	
	if canInput:
		match currentState:
			states.IDLE:
				if Input.is_action_just_pressed("jump"):
					jump()
				
				if Input.is_action_just_pressed("crouch | slide"):
					crouchStateChanges()
					

			states.WALK:
				if Input.is_action_just_pressed("run"):
					runStateChanges()
				
				if Input.is_action_just_pressed("jump"):
					jump()
				
				
				if Input.is_action_just_pressed("crouch | slide"):
					crouchStateChanges()
				
					
					
			states.RUN:
				if Input.is_action_just_pressed("run"):
					walkStateChanges()
				
				if Input.is_action_just_pressed("jump"):
					jump()
					
					
				if Input.is_action_just_pressed("crouch | slide"):
					slideStateChanges()
				
				
					
			states.CROUCH: 
				if Input.is_action_just_pressed("run") and !ceilingCheck.is_colliding():
					walkStateChanges()
				
				if Input.is_action_just_pressed("crouch | slide") :  #removed and !ceilingCheck.is_colliding for buggin in crouching
					walkStateChanges()
					
			states.SLIDE: 
				if Input.is_action_just_pressed("run"):
					slideStateChanges()
				
				if Input.is_action_just_pressed("jump"):
					jump()

				
				if Input.is_action_just_pressed("crouch | slide"):
					slideStateChanges()
					
			states.JUMP:
				if Input.is_action_just_pressed("crouch | slide"):
					slideStateChanges()
					
					
					
				if Input.is_action_just_pressed("jump"):
					jump()
					
					
	
			states.INAIR: 
				if Input.is_action_just_pressed("crouch | slide"):
					slideStateChanges()
					
					
				if Input.is_action_just_pressed("jump"):
					jump()
					
					
func applies(delta):
	#handles movement cases based on floor
	
	floorAngle = get_floor_normal() #get the angle of the floor
	
	if !is_on_floor():
		#modify the type of gravity to apply to the character, depending of his velocity (when jumping jump gravity, otherwise fall gravity)
		if velocity.y >= 0.0:
				velocity.y += jumpGravity * delta
				if currentState != states.SLIDE : currentState = states.JUMP
		else: 
			velocity.y += fallGravity * delta
			if currentState != states.SLIDE : currentState = states.INAIR 
			
		if currentState == states.SLIDE:
			if !startSlideInAir: 
				slideTime = -1 #if the character start slide on the grund, and the jump, the slide is canceled
				
		
		if hitGroundCooldown != hitGroundCooldownRef: hitGroundCooldown = hitGroundCooldownRef #reset the before bunny hopping value
		
		
	if is_on_floor():
		slopeAngle = rad_to_deg(acos(floorAngle.dot(Vector3.UP))) #get the angle of the slope 
		
		if currentState == states.SLIDE and startSlideInAir: startSlideInAir = false
		
		if hitGroundCooldown >= 0: hitGroundCooldown -= delta #disincremente the value each frame, when it's <= 0, the player lose the speed he accumulated while being in the air 
		
		if nbJumpsInAirAllowed != nbJumpsInAirAllowedRef: nbJumpsInAirAllowed = nbJumpsInAirAllowedRef #set the number of jumps possible
		
		
		
		#set the move state depending on the move speed, only when the character is moving
		if inputDirection != Vector2.ZERO and moveDirection != Vector3.ZERO:
			match currentSpeed:
				crouchSpeed:currentState = states.CROUCH 
				walkSpeed: currentState = states.WALK
				runSpeed: currentState = states.RUN 
				slideSpeed: currentState = states.SLIDE
				
		else:
			#set the state to idle
			if currentState == states.JUMP or currentState == states.INAIR or currentState == states.WALK or currentState == states.RUN: 
				if velocity.length() < 1.0: currentState = states.IDLE 
					
	
	if is_on_floor() or !is_on_floor():
		#manage the slide behaviour
		if currentState == states.SLIDE:
			#if character slide on an uphill, cancel slide
			
			#there is a bug here related to the uphill/downhill slide 
			#(simply said, i have to adjust manually the lastFramePosition value in order to make the character slide indefinitely downhill bot not uphill)
			
			
			if !startSlideInAir and lastFramePosition.y+0.1 < position.y: #don't know why i need to add a +0.1 to lastFramePosition.y, otherwise it breaks the mechanic some times
				slideTime = -1 
				
			if !startSlideInAir and slopeAngle < maxSlopeAngle:
				if slideTime > 0: 
					slideTime -= delta
					
			if slideTime <= 0: 
				timeBeforeCanSlideAgain = timeBeforeCanSlideAgainRef
				#go to crouch state if the ceiling is too low, otherwise go to run state 
				#if ceilingCheck.is_colliding(): crouchStateChanges()
				runStateChanges()
				
				
		if timeBeforeCanSlideAgain > 0.0: timeBeforeCanSlideAgain -= delta 
		
		if currentState == states.JUMP: floor_snap_length = 0.0 #the character cannot stick to structures while jumping
			
		if currentState == states.INAIR: floor_snap_length = 2.5 #but he can if he stopped jumping, but he's still in the air
		
		if jumpCooldown > 0.0: jumpCooldown -= delta
		
func move(delta):
	#direction input
	inputDirection = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
	
	
	#get the move direction depending on the input
	moveDirection = (cameraHolder.basis * Vector3(inputDirection.x, 0.0, inputDirection.y)).normalized()
		
	#move applies when the character is on the floor
	if is_on_floor():
		#if the character is moving
		if moveDirection:
			#apply slide move
			if currentState == states.SLIDE:
				if slopeAngle > maxSlopeAngle: desiredMoveSpeed += 3.0 * delta #increase more significantly desired move speed if the slope is steep enough
				else: desiredMoveSpeed += 2.0 * delta
				
				velocity.x = moveDirection.x * desiredMoveSpeed
				velocity.z = moveDirection.z * desiredMoveSpeed
				
				
			#apply smooth move when walking, crouching, running
			else:
				velocity.x = lerp(velocity.x, moveDirection.x * currentSpeed, moveAcceleration * delta)
				velocity.z = lerp(velocity.z, moveDirection.z * currentSpeed, moveAcceleration * delta)
				
				#cancel desired move speed accumulation if the timer is out
				if hitGroundCooldown <= 0: desiredMoveSpeed = velocity.length()
					
		#if the character is not moving
		else:
			#apply smooth stop 
			velocity.x = lerp(velocity.x, 0.0, moveDecceleration * delta)
			velocity.z = lerp(velocity.z, 0.0, moveDecceleration * delta)
			
			#cancel desired move speed accumulation
			desiredMoveSpeed = velocity.length()
			
	#move applies when the character is not on the floor (so if he's in the air)
	if !is_on_floor():
		if moveDirection:
			#apply dash move
			#if currentState == states.DASH: 
				#velocity.x = moveDirection.x * dashSpeed
				#velocity.z = moveDirection.z * dashSpeed 
				#
			#apply slide move
			if currentState == states.SLIDE:
				desiredMoveSpeed += 2.5 * delta
				
				velocity.x = moveDirection.x * desiredMoveSpeed
				velocity.z = moveDirection.z * desiredMoveSpeed
				
				
			#apply smooth move when in the air (air control)
			else:
				if desiredMoveSpeed < maxSpeed: desiredMoveSpeed += 1.5 * delta
				
				#here, set the air control amount depending on a custom curve, to select it with precision, depending on the desired move speed
				var contrdDesMoveSpeed : float = desiredMoveSpeedCurve.sample(desiredMoveSpeed/100)
				var contrdInAirMoveSpeed : float = inAirMoveSpeedCurve.sample(desiredMoveSpeed)
			
				velocity.x = lerp(velocity.x, moveDirection.x * contrdDesMoveSpeed, contrdInAirMoveSpeed * delta)
				velocity.z = lerp(velocity.z, moveDirection.z * contrdDesMoveSpeed, contrdInAirMoveSpeed * delta)
				
		else:
			#accumulate desired speed for bunny hopping
			desiredMoveSpeed = velocity.length()
			

	if desiredMoveSpeed >= maxSpeed: desiredMoveSpeed = maxSpeed #set to ensure the character don't exceed the max speed authorized
	
	lastFramePosition = position
			
func jump(): 
	#this function manage the jump behaviour, depending of the different variables and states the character is
	
	var canJump : bool = false #jump condition
	
		#in air jump
	if !is_on_floor():
		if jumpCooldown <= 0:
			
			if (nbJumpsInAirAllowed > 0) : 
				nbJumpsInAirAllowed -= 1
				canJump = true 
	#on floor jump
	else:
		canJump = true 
			
	#apply jump
	if canJump:
		currentState = states.JUMP
		velocity.y = jumpVelocity  #apply directly jump velocity to y axis velocity, to give the character instant vertical forcez
		canJump = false 
		

func crouchStateChanges():
	currentState = states.CROUCH
	currentSpeed = crouchSpeed
	moveAcceleration = crouchAcceleration 
	moveDecceleration = crouchDecceleration
	
	standHitbox.disabled = true
	crouchHitbox.disabled = false 
		
func walkStateChanges():
	currentState = states.WALK
	currentSpeed = walkSpeed
	moveAcceleration = walkAcceleration
	moveDecceleration = walkDecceleration
	
	standHitbox.disabled = false 
	crouchHitbox.disabled = true
	
	
func runStateChanges():
	currentState = states.RUN
	currentSpeed = runSpeed
	moveAcceleration = runAcceleration
	moveDecceleration = runDecceleration
	
	standHitbox.disabled = false 
	crouchHitbox.disabled = true 
	
func slideStateChanges():
	#condition here, the state is changed only if the character is moving (so has an input direction)
	if timeBeforeCanSlideAgain <= 0 and currentState != states.SLIDE:
		currentState = states.SLIDE 
		
		#change the start slide in air variable depending zon where the slide begun
		if !is_on_floor() and slideTime <= 0: startSlideInAir = true
		elif is_on_floor() and lastFramePosition.y >= position.y: #character can slide only on flat or downhill surfaces: 
			desiredMoveSpeed += slideSpeedAddon #slide speed boost when on ground (for balance purpose)
			startSlideInAir = false 
			
		slideTime = slideTimeRef
		currentSpeed = slideSpeed
		if inputDirection != Vector2.ZERO: slideVector = inputDirection 
		else: slideVector = Vector2(0, -1)
		
		standHitbox.disabled = true
		crouchHitbox.disabled = false 

	elif currentState == states.SLIDE:
		slideTime = -1.0
		timeBeforeCanSlideAgain = timeBeforeCanSlideAgainRef
		if ceilingCheck.is_colliding(): crouchStateChanges()
		else: runStateChanges()
		

@onready var slidespeedlines = $slidespeedlines

func animationchange():
	if currentState == states.IDLE:
		slidespeedlines.visible = false
		animation_state_machine.travel('Idle')
	if currentState == states.WALK:
		slidespeedlines.visible = false
		animation_state_machine.travel('Walk')
	if currentState == states.RUN:
		slidespeedlines.visible = false
		animation_state_machine.travel('Run')
	if currentState == states.SLIDE:
		slidespeedlines.visible = true
		animation_state_machine.travel('Idle')
	if currentState == states.INAIR:
		slidespeedlines.visible = false
		animation_state_machine.travel('Fall')
	if currentState == states.LANDING:
		slidespeedlines.visible = false
		%CameraHolder.shake_impact(0.25)
		animation_state_machine.travel('Jumpend')
	if currentState == states.JUMP :
		slidespeedlines.visible = false
		animation_state_machine.travel('Jumpstart')
		#camera_animation_player.play("Camerajump", 0)
	

var jumpaudioplayed = false
var slideaudioplayed= false
func audiochanges():
	if currentState == states.IDLE:
		jumpaudioplayed = false
		slideaudioplayed= false
		if jumpaudioplayed:
			jump_audio.stop()
		if falling.playing:
			falling.stop()
		if walk.playing:
			walk.stop()
		if run.playing:
			run.stop()
	elif currentState == states.WALK:
		jumpaudioplayed = false
		slideaudioplayed= false
		if jumpaudioplayed:
			jump_audio.stop()
		if falling.playing:
			falling.stop()
		if !walk.playing:
			walk.pitch_scale = randf_range(0.8,1.2)
			walk.play()
		if run.playing:
			run.stop()
	elif currentState == states.RUN:
		jumpaudioplayed = false
		slideaudioplayed= false
		if jumpaudioplayed:
			jump_audio.stop()
		if falling.playing:
			falling.stop()
		if !run.playing:
			run.play()
		if walk.playing:
			walk.stop()
	elif currentState == states.SLIDE and is_on_floor():
		jumpaudioplayed = false
		if jumpaudioplayed:
			jump_audio.stop()
		if falling.playing:
			falling.stop()
		if !slideaudioplayed:
			slide.play()
			slideaudioplayed = true
		if run.playing:
			run.stop()
		if walk.playing:
			walk.stop()
	elif currentState == states.INAIR:
		jumpaudioplayed = false
		slideaudioplayed= false
		if jumpaudioplayed:
			jump_audio.stop()
		if !falling.playing:
			falling.play()
		if slide.playing:
			slide.stop()
		if run.playing:
			run.stop()
		if walk.playing:
			walk.stop()
	elif currentState == states.JUMP:
		if !jumpaudioplayed:
			jump_audio.play()
			jumpaudioplayed = true
		if falling.playing:
			falling.stop()
		if slide.playing:
			slide.stop()
		if run.playing:
			run.stop()
		if walk.playing:
			walk.stop()
	else:
		jumpaudioplayed = false
		slideaudioplayed= false
		if jumpaudioplayed:
			jump_audio.stop()
		if falling.playing:
			falling.stop()
		if slide.playing:
			slide.stop()
		if run.playing:
			run.stop()
		if walk.playing:
			walk.stop()


	
	
func checklanding(delta):
	var was_in_air = currentState == states.INAIR
	
	
	if was_in_air and is_on_floor():
		currentState = states.LANDING
		landing_timer = 0.0
	if currentState == states.LANDING:
		landing_timer += delta
		if landing_timer >= landing_duration:
			if velocity.x == 0:
				currentState = states.IDLE
			else:
				currentState = states.WALK



var attacking = false
var attackcycle = 0

@onready var attack_state_machine = $CameraHolder/Camera3D/FirstpersonRig/PlayerAnimationTree.get("parameters/AttackStateMachine/playback")


func attack():
	if Input.is_action_just_pressed("shoot") and !attacking:
		player_animation_tree.set("parameters/AttackOneShot/request",true)
		if attackcycle == 0:
			attack_state_machine.travel('Attack1')
			if canfireslash:
				shootslash()
			attackcycle = 1
	if %SecondAttackTimer.time_left and attackcycle == 1 and Input.is_action_just_pressed("shoot") and !attacking:
		attack_state_machine.travel('Attack2')
		attackcycle = 0
	else:
		attackcycle = 0

func attack_toggle(value : bool): #changes the attacking variable to true when attack 1 animation is playing
	attacking = value
func can_damage(value: bool):
	$CameraHolder/Camera3D/FirstpersonRig/Armature/Skeleton3D/BoneAttachment3D/Swordnew.can_damage = value

#@onready var swordcollider = $swordcollider
#@onready var hitsound = $hitsound

#func callhit():
	#var collider_in_swordcollider = swordcollider.get_collider()
	#if collider_in_swordcollider and collider_in_swordcollider.has_method("hit"):
		#swordcollider.hit()
		#print(collider_in_swordcollider)
		#hitsound.play()

func slidekill():
	if currentState == states.SLIDE:
		var slidecollider = %slidekill.get_collider()
		if slidecollider and 'slidekilled' in slidecollider:
			slidecollider.slidekilled()
			%CameraHolder.shake_impact(2.0,10.0)


@onready var dashkillray = $CameraHolder/Camera3D/dashkill

var is_dashing = false
var dash_speed = 50.0
var dash_duration = 0.15
var original_position
@onready var monster_enemy = $"."
@onready var dashkillaudio = $dashkill
@onready var speedlines = $speedlines
@onready var dashaudio = $dash

@onready var targetsprite = $targetsprite

@onready var redcrosshair = $crosshair/crosshair


func showdashkillavailable():
	if is_dashing:  # Prevent multiple dashes at once
		return
		
	var dashkillcollider = dashkillray.get_collider()
	if dashkillcollider and 'dashkilled' in dashkillcollider and (currentState == states.JUMP or currentState == states.INAIR):
		targetsprite.visible = true
		redcrosshair.visible = true
	else:
		targetsprite.visible = false
		redcrosshair.visible = false


func dashkill():
	if is_dashing:  # Prevent multiple dashes at once
		return
		
	var dashkillcollider = dashkillray.get_collider()
	if dashkillcollider and 'dashkilled' in dashkillcollider:
		# Start the dash sequence
		start_dash_to_enemy(dashkillcollider)
	#else:start_dash_to_enemy(dashkillcollider) #i added this

func start_dash_to_enemy(enemy):
	is_dashing = true
	original_position = global_position
	
	# Calculate dash target (slightly in front of enemy to avoid clipping)
	var enemy_position = enemy.global_position
	var dash_direction = (enemy_position - global_position).normalized()
	var dash_target = enemy_position - dash_direction * 1.5                        # Stop 1.5 units before enemy
	
	dashaudio.pitch_scale = randf_range(0.8,1.2)
	dashaudio.play()
	player_animation_tree.set("parameters/AttackOneShot/request",true)
	attack_state_machine.travel('Attack2')
	
	# Create dash tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUART)
	
	# Dash to enemy
	tween.tween_property(self, "global_position", dash_target, dash_duration)
	%CameraHolder.shake_impact(5.0,dash_duration)
	speedlines.visible = true
	
	# When dash completes, execute the kill
	tween.tween_callback(execute_kill.bind(enemy))
func execute_kill(enemy):
	# Kill the enemy
	enemy.dashkilled()
	dashkillaudio.play()
	
	# Wait for animation to finish before allowing next dash
	
	is_dashing = false
	speedlines.visible = false
	
@onready var controlmenu = $controlmenu

func applyshake(intensity:float,time:float):
		%CameraHolder.shake_impact(intensity,time)


func _input(event):
	if event.is_action_pressed("dash_kill") and (currentState == states.INAIR or currentState == states.JUMP): # add "dash_kill" in Input Map
		dashkill()
	if event.is_action_pressed("groundslam")  and (currentState == states.INAIR or currentState == states.JUMP) :
		slam()
	if event.is_action_pressed("tutorial"):
		controlmenu.visible = true
	if event.is_action_released("tutorial"):
		controlmenu.visible = false
var slamming = false
var slam_jump_force = 400.0   # how high you pop up
var slam_gravity = 600.0       # downward acceleration
var slam_down_boost = -200.0   # instant downward pull when switching phases

var slam_phase = "none"

func slam():
	if not slamming:
		slamming = true
		slam_phase = "up"
		velocity.y = slam_jump_force  # go upward a bit
		speedlines.visible = false

@onready var groundslamaudio = $groundslamaudio

func applyslam(delta):
	var damage_radius = 10.0
	if slamming:
		if slam_phase == "up":
			speedlines.visible = false
			# let character rise naturally with normal gravity
			#velocity.y += 10.0 * delta
			
			# when upward motion ends -> switch to slam
			if velocity.y >= 0:
				slam_phase = "down"
				velocity.y += slam_down_boost  # snap downward
		
		elif slam_phase == "down":
			# apply extra-strong gravity
			velocity.y -= slam_gravity * delta
			speedlines.visible = true
			
			if is_on_floor():
				_on_slam_impact()
				groundslamaudio.play()

func _on_slam_impact():
	var damage_radius = 10.0
	slamming = false
	slam_phase = "none"
	speedlines.visible = false
	%CameraHolder.shake_impact(15.0,20.0)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if position.distance_to(enemy.position) <= damage_radius:
			if enemy.has_method("slamkilled"):
				enemy.slamkilled()

@onready var bloodoverlay = $bloodoverlay

var max_health = 100
var current_health: int = max_health
@onready var damage_cooldown_timer = $damage_cooldown_timer
var can_take_damage = true
var is_dead = false

@onready var takingdamage = $takingdamage

func take_damage(amount : int):
	if is_dead:
		return
	if can_take_damage:
		current_health -= amount
		bloodoverlay.visible = true
		%CameraHolder.shake_impact(5.0,1.0)
		takingdamage.play()
		damage_cooldown_timer.start()
		#await get_tree().create_timer(2.0).timeout
		#bloodoverlay.visible = false
	
	if current_health <= 0:
		is_dead = true
		playerdead()

func _on_damage_cooldown_timer_timeout():
	can_take_damage = true
	current_health = max_health
	bloodoverlay.visible = false

func playerdead():
	Gamemanager.kill_count = 0
	is_dead = true
	call_deferred("_reload_scene_safely")

func _reload_scene_safely():
	get_tree().reload_current_scene()

@onready var overdrive = $OVERDRIVE

func overdriveshow():
	overdrive.visible = true
	await get_tree().create_timer(1.0).timeout
	overdrive.visible = false

@onready var youwon = $YOUWON
func showyouwon():
	youwon.visible = true

@onready var marker_3d = $Marker3D
@onready var slasheffect = $slasheffect

var slash_scene = preload("res://slash/slash.tscn")
func shootslash():
	var slash = slash_scene.instantiate()
	get_tree().current_scene.add_child(slash)
	#slash.global_position = %CameraHolder.global_position + -%CameraHolder.global_transform.basis.z * -1
	slash.direction = -%CameraHolder.global_transform.basis.z.normalized()
	slash.global_position = marker_3d.global_position
	slasheffect.play()
	applyshake(20.0, 10.0)
	#var forward_dir = marker_3d.global_transform.basis.z.normalized()
	#var up_dir = Vector3.UP
	#slash.look_at(slash.global_position + forward_dir, up_dir)

@onready var hellcleaver = $CameraHolder/Camera3D/FirstpersonRig/Armature/Skeleton3D/BoneAttachment3D/Swordnew/Hellcleaver
@onready var fire = $CameraHolder/Camera3D/FirstpersonRig/Armature/Skeleton3D/BoneAttachment3D/Swordnew/Fire
@onready var small_trails = $"CameraHolder/Camera3D/FirstpersonRig/Armature/Skeleton3D/BoneAttachment3D/Swordnew/small trails"


@onready var monster = preload("res://Enemy/Enemy/monster_enemy.tscn")


var canfireslash = false
func killeffect():
	if Gamemanager.kill_count == 5:
		hellcleaver.visible = true
	if Gamemanager.kill_count == 7:
		small_trails.emitting = true
	if Gamemanager.kill_count == 10:
		fire.emitting = true
		canfireslash = true
		#for i in range(10):
			#
			#var monsterspawn = monster.instantiate()
			#
			#monsterspawn.position = position + Vector3(
				#randf_range(-20, 20), 
				#0, 
				#randf_range(-20, 20)
			#)
			#
			#get_parent().add_child(monsterspawn)
			#await get_tree().create_timer(0.1).timeout


var wallnormal
var press_force
var waswallrunning = false
func wallrun(delta):
	if Input.is_action_pressed("jump"):
		if is_on_wall():
			var collision = get_slide_collision(0) #GETTING THE FIRST COLLISION
			if collision:
				wallnormal = collision.get_normal() #THE OUTWARD FACING DIRECTION OF THE WALL
				
				velocity.y = 0
				
				var press_force = -wallnormal * 5.0  #THE PRESSING FORCE OPPOSITE TO NORMAL
				velocity += press_force * delta
				velocity += -%CameraHolder.transform.basis.z * 1000.0 * delta
				waswallrunning = true
	if Input.is_action_just_released("jump") and is_on_wall():
		print("released")
		var bounce_force = wallnormal * 20.0
		var upward_boost = Vector3(0, 10.0, 0)
		velocity += bounce_force + upward_boost
		
	if waswallrunning and !is_on_wall():
		print("released")
		var bounce_force = wallnormal * 20.0
		var upward_boost = Vector3(0, 10.0, 0)
		velocity += bounce_force + upward_boost
		waswallrunning = false
	
