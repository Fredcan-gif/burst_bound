extends Node2D

var player = null
var goal_reached = false

func _ready():
	GameManager.is_tutorial = true
	player = get_tree().get_first_node_in_group("Player")
	player.can_jump = false
	player.can_dash = false
	$TutorialExit.body_entered.connect(_on_goal_reached)
	Dialogue.start_dialogue([
		{"name": "???", "text": "Hello Test Subject."},
		{"name": "???", "text": "Thank you for participating in this experiment, this will be over quickly if you cooperate with us."},
		{"name": "You", "text": "I'll only do so if you let me free once this is all over!"},
		{"name": "???", "text": "You have our word, now onto the experiment. Ahead of you is a series of rooms, each designed to challenge your skills and mobility."},
		{"name": "???", "text": "Complete all of them without fail, and we shall let you free."},
		{"name": "???", "text": "Get to the exit of this room by moving left and right."},
	])

func _on_goal_reached(body):
	if body.is_in_group("Player") and not goal_reached:
		goal_reached = true
		TransitionLayer.play_full_transition("res://Scenes/tutorial_room_2.tscn")
