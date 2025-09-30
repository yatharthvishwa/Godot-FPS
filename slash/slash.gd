extends Area3D

@export var speed: float = 30.0
var direction: Vector3 = Vector3.ZERO

func _ready():
	pass
	#look_at(global_position + direction, Vector3.UP)

func _process(delta):
	global_position += direction * speed * delta
	if direction != Vector3.ZERO:
		look_at(global_position + -direction, Vector3.UP)
	#rotation.z = deg_to_rad(-45)

func _on_body_entered(body: Node):
	if body.is_in_group("enemy"):
		if body.has_method("dashkilled"):  # call enemy death
			body.call_deferred("dashkilled")
		await get_tree().create_timer(1.0).timeout
		queue_free()  # remove the slash after hitting
	else:
		await get_tree().create_timer(1.0).timeout
		queue_free()
