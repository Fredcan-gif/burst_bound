extends Node2D

var player = null
var goal_reached = false

func _ready():
	GameManager.is_tutorial = true
	MusicManager.play_for_difficulty("tutorial")
	player = get_tree().get_first_node_in_group("Player")
	player.can_jump = true
	player.can_dash = false
	$TutorialExit.body_entered.connect(_on_goal_reached)
	Dialogue.start_dialogue([
		{"name": "???", "text": "Let's move on to jumping."},
		{"name": "???", "text": "There are various traps and gaps scattered around the area, jump over them to pass."},
		{"name": "???", "text": "Don't worry we fool proofed these traps to avoid any future lawsuits, if you touch them then you will be brought back to the start."},
	])

func _on_goal_reached(body):
	if body.is_in_group("Player") and not goal_reached:
		goal_reached = true
		TransitionLayer.play_full_transition("res://Scenes/tutorial_room_3.tscn")
