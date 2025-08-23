extends CharacterBody3D
func _ready():
	pass
	#for child in %WorldModel.find_children("*", "VisualInstance3D"): #this hides everything in worldmodel
	#	child.set_layer_mask_value()


@export var look_sensitivity : float = 0.006
@export var jump_velocity := 6.0
@export var auto_bhop := true
@export var walk_speed := 7.0
@export var sprint_speed := 15.0

#not really using them
#const HEADBOB_MOVE_AMOUNT = 0.06
#const HEADBOB_FREQUENCY = 2.4
#var headbob_time := 0.0

#air movement settings
@export var air_cap := 0.85 #can surf steeper ramps if this is higher, makes it easier to stick and bhop
@export var air_accel :=800.0
@export var air_move_speed := 500.0

func is_surface_too_steep(normal : Vector3) -> bool:
	var max_slope_ang_dot = Vector3(0,1,0).rotated(Vector3(1.0,0,0), self.floor_max_angle).dot(Vector3(0,1,0))
	if normal.dot(Vector3(0,1,0)) < max_slope_ang_dot:
		return true	
	return false

func clip_velocity(normal: Vector3, overbounce : float,delta:float) -> void:
	#pushing you away from wall
	var backoff := self.velocity.dot(normal) * overbounce
	if backoff >= 0: return	
	
	var change := normal * backoff
	self.velocity -= change
	
	#not sure why this is necessary but keeping it
	var adjust := self.velocity.dot(normal)
	if adjust < 0.0:
		self.velocity -= normal * adjust

var wish_dir := Vector3.ZERO #used to store the input direction we're pressing

func get_move_speed() -> float:
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed


func _unhandled_input(event):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * look_sensitivity) #event.relative.x = mouse movement ALONG x axis i.e left/right
		%Camera3D.rotate_x(-event.relative.y * look_sensitivity)
		%Camera3D.rotation.x = clamp(%Camera3D.rotation.x , deg_to_rad(-90),deg_to_rad(90))

func _process(delta):
	pass

func _handle_air_physics(delta) -> void :
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	#classic recipe
	#we take the dot product of current velocity of player with the wish dirction they wanna move in
	#this lets us know how fast the player is already moving in the direction they wanna move in
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	#max speed limit
	#cap speed will be 0 if the player is not pressing anything
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	#how much to get to speed player wishes
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap) #works without this but sticking to tut # makes sure we're not increasing the speed past speed cap
		self.velocity += accel_speed * wish_dir
		
	if is_on_wall():
		if is_surface_too_steep(get_wall_normal()):
			self.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		
		else:
			self.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		clip_velocity(get_wall_normal(), 1 , delta) #allows surf
	

func _handle_ground_physics(delta) -> void :
	self.velocity.x = wish_dir.x * get_move_speed()
	self.velocity.z = wish_dir.z * get_move_speed()
	

func _physics_process(delta):
	var input_dir = Input.get_vector("move_left","move_right","move_forward","move_back").normalized()
	#depending on character facing, input should be transformed
	#This rotates the input vector into the character’s local orientation.
	wish_dir = self.global_transform.basis * Vector3(input_dir.x ,0 ,input_dir.y)
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
		
	move_and_slide()
