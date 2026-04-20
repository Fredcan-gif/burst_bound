extends Node2D


func _on_quit_pressed():
	get_tree().quit()

func _on_start_pressed() -> void:
	GameManager.score = 0 # Reset score for new game
	var first_map = GameManager.get_random_map()
	TransitionLayer.play_full_transition(first_map)
