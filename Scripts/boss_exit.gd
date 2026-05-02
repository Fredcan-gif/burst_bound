extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		GameManager.complete_stage()
		TransitionLayer.play_full_transition(GameManager.get_next_map())
