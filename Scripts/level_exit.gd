extends Area2D

func _on_body_entered(body):
	if body.is_in_group("Player"):
		print("Player hit the exit!") # Check if this prints in the console
		GameManager.add_point()
		TransitionLayer.play_full_transition(GameManager.get_random_map())
