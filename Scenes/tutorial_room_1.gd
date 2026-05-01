extends Node2D

var player = null
var goal_reached = false

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	$TutorialExit.body_entered.connect(_on_goal_reached)
	Dialogue.start_dialogue([
		{"name": "???", "text": "Move left and right to navigate the world."},
		{"name": "???", "text": "You know what to do."},
	])

func _on_goal_reached(body):
	if body.is_in_group("Player") and not goal_reached:
		goal_reached = true
		TransitionLayer.play_full_transition("res://Scenes/tutorial_room_2.tscn")
