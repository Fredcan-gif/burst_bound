extends Node2D

var player = null
var goal_reached = false

func _ready():
	GameManager.is_tutorial = true
	MusicManager.play_for_difficulty("tutorial")
	player = get_tree().get_first_node_in_group("Player")
	player.can_jump = true
	player.can_dash = true
	$TutorialExit.body_entered.connect(_on_goal_reached)
	Dialogue.start_dialogue([
		{"name": "???", "text": "If you haven't noticed yet you can dash in 6 directions, I am confident that you can connect the dots from there."},
		{"name": "???", "text": "Use them to get past through tricky areas and avoid obstacles."},
		{"name": "???", "text": "Don't worry, just a few more rooms and we will set you free"},
	])

func _on_goal_reached(body):
	if body.is_in_group("Player") and not goal_reached:
		goal_reached = true
		TransitionLayer.play_full_transition("res://Scenes/tutorial_room_5.tscn")
