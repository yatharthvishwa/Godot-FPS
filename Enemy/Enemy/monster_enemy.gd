extends Enemy

@onready var footstepsaudio = $skin/Armature/footsteps
@onready var runaudio = $skin/Armature/run
@onready var animation_player = $skin/AnimationPlayer

func _physics_process(delta):
	move_to_player(delta)


func _on_attack_timer_timeout():
	if position.distance_to(player.position) < attack_radius:
		punch_attack_animation()

func punch_attack_animation():
	$AnimationTree.set("parameters/PunchOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func hit():
	move_state_machine.travel('Death')
	velocity = Vector3.ZERO
	#$AnimationTree.active = false
	enemyhitbox.disabled = true
	runaudio.stop()
	footstepsaudio.stop()
	set_physics_process(false)
	set_process(false)
	print('enemyhit')

@onready var enemymesh = $skin
@onready var debris = $explosion/debris
@onready var blood = $explosion/blood
@onready var slidekillaudio = $skin/Armature/slidekill
@onready var enemyhitbox = %enemyhitbox

func slidekilled():

	move_state_machine.travel('Death')
	velocity = Vector3.ZERO
	#$AnimationTree.active = false
	enemyhitbox.disabled = true
	slidekillaudio.play()
	debris.emitting = true
	blood.emitting = true
	runaudio.stop()
	enemymesh.visible = false
	footstepsaudio.stop()
	set_physics_process(false)
	set_process(false)
	#print('enemyhit')

@onready var dashkillcollision_shape_3d = $dashkillhitbox2/CollisionShape3D

func dashkilled():
	move_state_machine.travel('Death')
	velocity = Vector3.ZERO
	#$AnimationTree.active = false
	enemyhitbox.disabled = true
	slidekillaudio.play()
	debris.emitting = true
	blood.emitting = true
	runaudio.stop()
	enemymesh.visible = false
	footstepsaudio.stop()
	set_physics_process(false)
	set_process(false)
	dashkillcollision_shape_3d.disabled = true
	get_tree().call_group("world", "on_enemy_dashkilled", self)
	#queue_free()
func slamkilled():
	move_state_machine.travel('Death')
	velocity = Vector3.ZERO
	enemyhitbox.disabled = true
	debris.emitting = true
	blood.emitting = true
	runaudio.stop()
	enemymesh.visible = false
	footstepsaudio.stop()
	set_physics_process(false)
	set_process(false)
	dashkillcollision_shape_3d.disabled = true
var candie = false

func dietoggle(value:bool):
	candie = value
