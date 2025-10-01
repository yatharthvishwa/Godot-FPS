extends Node3D

@export var speed: float = 50.0
var player: Node3D

func _ready():
	player = get_tree().get_first_node_in_group("player")

var last_direction: Vector3 = Vector3.ZERO
func _process(delta):
	if player:
		#var direction = (player.global_position - global_position).normalized()
		var direction = player.global_position - global_position
		direction.y = 0
		if direction.length() > 10:
			# Only update if there's a valid horizontal difference
			last_direction = direction.normalized()
		
		# Move in last known valid direction
		global_position += last_direction * speed * delta
		
		#face the player but not in y axis
		var target = player.global_position
		target.y = global_position.y  # keep same height
		look_at(target, Vector3.UP)


func _on_body_entered(body):
	print("bodyentered")
	if player.has_method("take_damage"):
		
		player.take_damage(10)
