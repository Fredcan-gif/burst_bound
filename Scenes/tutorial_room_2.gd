extends Node2D

var player = null
var goal_reached = false

func _ready():
	GameManager.is_tutorial = true
	player = get_tree().get_first_node_in_group("Player")
	player.can_jump = true
	player.can_dash = false
	$TutorialExit.body_entered.connect(_on_goal_reached)
	Dialogue.start_dialogue([
		{"name": "???", "text": "Now try jumping. Press the jump button to get over the gaps and obstacles."},
		{"name": "???", "text": "Don't worry you will be brought back to the start if you fail."},
	])

func _on_goal_reached(body):
	if body.is_in_group("Player") and not goal_reached:
		goal_reached = true
		TransitionLayer.play_full_transition("res://Scenes/tutorial_room_3.tscn")
