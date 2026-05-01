extends Area2D

@export var spawn_point: Vector2 = Vector2.ZERO

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.global_position = spawn_point
		body.velocity = Vector2.ZERO
