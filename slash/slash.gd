extends Area3D

@export var speed: float = 30.0
var direction: Vector3 = Vector3.ZERO
func _process(delta):
	global_position += direction * speed * delta
	


func _on_body_entered(body: Node):
	if body.is_in_group("enemy"):
		if body.has_method("dashkilled"):  # call enemy death
			body.dashkilled()
		
		#queue_free()  # remove the slash after hitting
