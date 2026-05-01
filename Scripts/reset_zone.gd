extends Area2D

@export var spawn_marker: NodePath = ""

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.can_move = false
		body.velocity = Vector2.ZERO
		
		var spawn_pos = get_node(spawn_marker).global_position if spawn_marker else body.global_position
		
		TransitionLayer.play_full_transition_in_place(spawn_pos, body)
