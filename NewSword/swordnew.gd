extends Node3D


var can_damage = false
@onready var hitsound = $hitsound

func _process(delta):
	if can_damage:
		var swordcollider = $swordcollider.get_collider()
		if swordcollider and 'hit' in swordcollider:
			swordcollider.hit()
			hitsound.play()
