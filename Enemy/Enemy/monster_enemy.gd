extends Enemy

@onready var footstepsaudio = $skin/Armature/footsteps
@onready var runaudio = $skin/Armature/run
@onready var animation_player = $skin/AnimationPlayer


func _physics_process(delta):
	move_to_player(delta)
	if !enemydead:
		if position.distance_to(player.position) < attack_radius:
			if can_attack:
				punch_attack_animation()
				start_attack_cooldown()

var can_attack = true

func start_attack_cooldown():
	can_attack = false
	await get_tree().create_timer(1.0).timeout
	can_attack = true



func _on_attack_timer_timeout():
	pass
	#if !enemydead:
		#if position.distance_to(player.position) < attack_radius:
			#punch_attack_animation()

func punch_attack_animation():
	$AnimationTree.set("parameters/PunchOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

var enemydead = false
func hit():
	Gamemanager.add_kill()
	enemydead = true
	move_state_machine.travel('Death')
	velocity = Vector3.ZERO
	$AnimationTree.set("parameters/PunchOneShot/abort", true)
	$AnimationTree.set("parameters/PunchOneShot/active", false)
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
	Gamemanager.add_kill()
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
	Gamemanager.add_kill()
	get_tree().call_group("world", "on_enemy_dashkilled", self) #this is for music
func slamkilled():
	Gamemanager.add_kill()
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

var ispunching = false
func ispunchingtoggle(value : bool):
	ispunching = value
	
@onready var damagewaittimer = $Timer/damagewaittimer
var damage_given_to_player = false
#func punchdamage():
	#if ispunching and position.distance_to(player.position) < attack_radius:
		#var playergroupintree = get_tree().get_nodes_in_group("player")
		#if playergroupintree.size() > 0:
			#var playernode = playergroupintree[0] # get the actual player node
			#print("player in position")
			#if playernode.has_method("take_damage"):
				#pass
				#damagewaittimer.start()
				#damage_given_to_player = true
				#playernode.take_damage(50)
				#print("damagesent")

#func _on_damagewaittimer_timeout():
	#print("timeout")
	#damage_given_to_player = false
	#var playergroupintree = get_tree().get_nodes_in_group("player")
	#if playergroupintree.size() > 0:
		#var playernode = playergroupintree[0]
		#playernode.current_health = playernode.max_health

func _on_punchhitbox_body_entered(body):
	print("entered")
	if ispunching: #this is not being turned on
		var playergroupintree = get_tree().get_nodes_in_group("player")
		if playergroupintree.size() > 0:
			var playernode = playergroupintree[0]
			if playernode.has_method("take_damage"):
					#damagewaittimer.start()
					#damage_given_to_player = true
					playernode.take_damage(50)
					print("damagesent")
					
