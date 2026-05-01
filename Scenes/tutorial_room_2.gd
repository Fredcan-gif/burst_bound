extends Node2D

var player = null
var goal_reached = false

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	$TutorialExit.body_entered.connect(_on_goal_reached)
	Dialogue.start_dialogue([
		{"name": "???", "text": "Now try jumping. Press the jump button to get over obstacles."},
		{"name": "???", "text": "You can also jump off walls."},
	])

func _on_goal_reached(body):
	if body.is_in_group("Player") and not goal_reached:
		goal_reached = true
		Dialogue.start_dialogue([
			{"name": "???", "text": "Good. You're getting the hang of it."},
		])
		TransitionLayer.play_full_transition("res://Scenes/tutorial_2.tscn")
