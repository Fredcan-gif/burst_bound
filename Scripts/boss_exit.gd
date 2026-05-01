extends Area2D

func _on_body_entered(body):
	if body.is_in_group("Player"):
		GameManager.add_point()
		TransitionLayer.play_full_transition(GameManager.get_next_map())
