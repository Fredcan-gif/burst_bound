extends Area2D

@export var next_scene: String = ""

func _on_body_entered(body):
	if body.is_in_group("Player"):
		TransitionLayer.play_full_transition(next_scene)
