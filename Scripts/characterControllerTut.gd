extends CharacterBody3D

#Player nodes
@onready var nek = $Nek
@onready var Head = $Nek/Head
@onready var Standing_collision_shape = $Standing_collision_shape
@onready var Crouching_collision_shape = $Crouching_collision_shape
@onready var roof_check = $RoofCheck
@onready var camera_3d = $Nek/Head/eyes/Camera3D
@onready var eyes = $Nek/Head/eyes


var direction = Vector3.ZERO

@export var mouse_sensitivity = 0.4

@export var walking_speed = 5.0
@export var sprinting_speed = 8.0
@export var crouching_speed = 3.0
@export var freelooking_lerp = 10.0 #how gradually will camera move back when you stop freelooking
var free_look_tilt_amount = 8
var current_speed = 5.0
var jump_velocity = 4.5
var lerp_speed = 10.0 # this brings a more gradual speed down/ speed up this is also being used in crouching speed control
var crouching_depth = -0.5 #how much lower the camera will be when we crouch

#States
var WALKING = false
var SPRINTING = false
var CROUCHING = false
var FREELOOKING = false
var SLIDING = false
var SLIDEJUMPBOOST = false

#slide vars
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0
var slide_jump_boost_velocity = 8.2

#Headbobing vars
const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed =10.0
	  #speed will be how fast we move side to side and up and down, intensity will be by how much
const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.10 
const head_bobbing_crouching_intensity = 0.05
	  #now we'll need variables to keep track of where we are in the sin function
var head_bobbing_vector = Vector2.ZERO #so this vector has x and y value so it'll keep track of up and down and side to side
var head_bobbing_index = 0.0 #this is how far along the sin function we are 
var head_bobbing_current_intesity = 0.0 #we'll just swap this value with respect to state
 




#mouse capturing logic
#for capturing the mouse inside the window we'll use the ready function
#the ready function runs at the beginning of execution
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#mouse looking logic
func _input(event): #input event captures every input, so we have to filter mouse input
	if event is InputEventMouseMotion: #now we know the input is mouse
		
		#FREELOOKING LOGIC

		if FREELOOKING: 
			nek.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity)) #rotating neck when freelooking
			nek.rotation.y = clamp(nek.rotation.y, deg_to_rad(-120), deg_to_rad(120))
			
			
		else:
			#lets rotate the player by amount of mouse moved so we'll rotate the player around y axis by the amount of motion of mouse in the x axis
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity)) # the player rotates a lot even after multiplying event.relative.x by mousesensitibity so we have to covert the whole func from radian to deg also minus is added because when mouse goes right the player look left so that the reverse of what we want so we add a negative to eventrelativex
		#we just need to rotate the head up and down AROUND X AXIS
		Head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		Head.rotation.x = clamp(Head.rotation.x , deg_to_rad(-89) , deg_to_rad(89))
		

func _physics_process(delta):
	#getting movement input also adding it on top as if it was at bottom the funct above it would not recognize the var
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	#Crouching
	
	if Input.is_action_pressed("crouch") or SLIDING: #so crouching is dominant meaning if we are sprinting and crouching at the same time, we'll just crouch that's why where putting the whole sprinting function under the crouching func
		current_speed = crouching_speed
		Head.position.y = lerp(Head.position.y, crouching_depth, delta * lerp_speed) #this will move the head lower when crouching keep in mind this will not put the head back to original height as well as gradually too as we added lerp
		
		Standing_collision_shape.disabled = true #disabling standing collision shape when crouching
		Crouching_collision_shape.disabled = false #enabling crouching collision shape
		
		#SLIDING START
		
		if SPRINTING and input_dir != Vector2.ZERO: #makes sure we are sprinting and have some velocity when we slide
			
			SLIDING = true
			slide_timer = slide_timer_max
			print("start")
			slide_vector = input_dir #this line will capture our current input and repeat it for slide
			if Input.is_action_pressed("move_back") and SLIDING: #trying to cancel our slide
				SLIDING = false
		
		WALKING = false
		SPRINTING = false
		CROUCHING = true
		
		
		#Standing
		
	elif !roof_check.is_colliding(): #if ray is not colliding with roof then the player will get up to its standing collision height 
		Standing_collision_shape.disabled = false
		Crouching_collision_shape.disabled = true
		
		Head.position.y = lerp(Head.position.y, 0.0, delta * lerp_speed) #head will move back to 1.8 height if we're not crouching as well as gradually too as we added lerp
			#checking what button we're pressing
		
		#Sprinting
		
		if Input.is_action_pressed("sprint"):
			current_speed = sprinting_speed
			
			WALKING = false
			SPRINTING = true
			CROUCHING = false
			
		else:
			
			#Walking
			
			current_speed = walking_speed
			WALKING = true
			SPRINTING = false
			CROUCHING = false
	
	#Free looking
	
	if SLIDING:
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, deg_to_rad(5.0), delta * lerp_speed)
	
	elif Input.is_action_pressed("freelook") :
		FREELOOKING = true
		camera_3d.rotation.z = -deg_to_rad(nek.rotation.y * free_look_tilt_amount)#y around neck rotate karegi toh
	else:
		FREELOOKING = false
		nek.rotation.y = lerp(nek.rotation.y, 0.0, delta * freelooking_lerp) #resets rotation when you stop freelooking and also does it gradually by lerp
		camera_3d.rotation.z = lerp(camera_3d.rotation.z,0.0 , delta * lerp_speed )
	
	#Handle SLIDING(ending a slide)
	
	if SLIDING:
		slide_timer -=delta #this line does the timer countdown
		if slide_timer <=0:
			SLIDING = false
			print("slide end")
			FREELOOKING = false
		
	
	#HANDLE HeadBOB
	
	if SPRINTING:
		head_bobbing_current_intesity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif WALKING:
		head_bobbing_current_intesity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif CROUCHING:
		head_bobbing_current_intesity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
		
	if is_on_floor() and !SLIDING and !SLIDEJUMPBOOST and  input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2) + 0.5
		
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (head_bobbing_current_intesity / 1.75), delta*lerp_speed) #divinding by 2 as in headbob it moves more from side to side than up and down
		 #ngl dividing the y headbob by 0.5 gives more aggresive feeling and can be used for future
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * (head_bobbing_current_intesity ), delta*lerp_speed)
	else :
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*lerp_speed)
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerp_speed)
	
	
	
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		SLIDEJUMPBOOST = false
	
	
	#SLIDEBOOSTJUMP LOGIC
	
	if Input.is_action_just_pressed("jump") and SLIDING and is_on_floor():
		velocity.y = slide_jump_boost_velocity
		SLIDEJUMPBOOST = true
	else : SLIDEJUMPBOOST = false


	
	
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() , delta * lerp_speed) #this make stopping more gradual
					#motion.x = lerp(motion.x, 0, 0.2)  # Gradually approach zero velocity               
	
	#Makes the slide vector what we last input
	
	if SLIDING:
		direction = (transform.basis * Vector3(slide_vector.x, 0.0, slide_vector.y)).normalized()
		#so slide_vector is a vec2 that will represent 2d input and converts it into to sliding input when we are sliding
		#Vector3(slide_vector.x, 0.0, slide_vector.y) this converts 2D vector into 3D by placing x → X axis , y → Z axis , 0.0 → Y axis since we dont want us to move up vertically
		#transform.basis is orentation of the player multiplying it by vec3 transforms it from world space to local space 
		
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		#SLIDING LOGIC
		
		if SLIDING:
			velocity.x = direction.x * (slide_timer + 0.5) * slide_speed #multiplying by slide timer as it would be fast at start like sliding
			velocity.z = direction.z * (slide_timer + 0.5) * slide_speed
		
		
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
