extends CharacterBody3D

#class name
class_name PlayerCharacter

#states variables
enum states
{
	IDLE, WALK, RUN, CROUCH, SLIDE, JUMP, INAIR, ONWALL, DASH, GRAPPLE
}
var currentState 

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


func _ready():
	
	
	#$CameraHolder/Camera3D/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size() #viewport size for weapons
	
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

func _process(_delta):
	#the behaviours that is preferable to check every "visual" frame
	
		inputManagement()
		
	
func _physics_process(delta):
	#$CameraHolder/Camera3D/SubViewportContainer/SubViewport/view_model_camera.global_transform = $CameraHolder/Camera3D.global_transform
	#the behaviours that is preferable to check every "physics" frame
	
	applies(delta)
	
	move(delta)
	
	
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
	#general appliements
	
	floorAngle = get_floor_normal() #get the angle of the floor
	
	if !is_on_floor():
		#modify the type of gravity to apply to the character, depending of his velocity (when jumping jump gravity, otherwise fall gravity)
		if velocity.y >= 0.0:
				if currentState != states.GRAPPLE: velocity.y += jumpGravity * delta
				if currentState != states.SLIDE and currentState != states.DASH and currentState != states.GRAPPLE: currentState = states.JUMP
		else: 
			if currentState != states.GRAPPLE: velocity.y += fallGravity * delta
			if currentState != states.SLIDE and currentState != states.DASH and currentState != states.GRAPPLE: currentState = states.INAIR 
			
		if currentState == states.SLIDE:
			if !startSlideInAir: 
				slideTime = -1 #if the character start slide on the grund, and the jump, the slide is canceled
				
		#if currentState == states.DASH: velocity.y = 0.0 #set the y axis velocity to 0, to allow the character to not be affected by gravity while dashing
		
		if hitGroundCooldown != hitGroundCooldownRef: hitGroundCooldown = hitGroundCooldownRef #reset the before bunny hopping value
		
		#if coyoteJumpCooldown > 0.0: coyoteJumpCooldown -= delta
		
	if is_on_floor():
		slopeAngle = rad_to_deg(acos(floorAngle.dot(Vector3.UP))) #get the angle of the slope 
		
		if currentState == states.SLIDE and startSlideInAir: startSlideInAir = false
		
		if hitGroundCooldown >= 0: hitGroundCooldown -= delta #disincremente the value each frame, when it's <= 0, the player lose the speed he accumulated while being in the air 
		
		if nbJumpsInAirAllowed != nbJumpsInAirAllowedRef: nbJumpsInAirAllowed = nbJumpsInAirAllowedRef #set the number of jumps possible
		
		
		
		#set the move state depending on the move speed, only when the character is moving
		
		
		if inputDirection != Vector2.ZERO and moveDirection != Vector3.ZERO:
			match currentSpeed:
				crouchSpeed: currentState = states.CROUCH 
				walkSpeed: currentState = states.WALK
				runSpeed: currentState = states.RUN 
				slideSpeed: currentState = states.SLIDE 
				dashSpeed: currentState = states.DASH 
				
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
			if currentState == states.DASH: 
				velocity.x = moveDirection.x * dashSpeed
				velocity.z = moveDirection.z * dashSpeed 
				
			#apply slide move
			elif currentState == states.SLIDE:
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
		
		
