extends Node2D

var player = null
var goal_reached = false

func _ready():
	GameManager.is_tutorial = true
	player = get_tree().get_first_node_in_group("Player")
	player.can_jump = true
	player.can_dash = true
	$TutorialExit.body_entered.connect(_on_goal_reached)
	Dialogue.start_dialogue([
		{"name": "???", "text": "That's the basics finished."},
		{"name": "???", "text": "Next up is your main method of traversal. Do you see that device on you?"},
		{"name": "You", "text": "Yeah I can't seem to take it off."},
		{"name": "???", "text": "We surgically implanted it on you, we figured it would make things easier."},
		{"name": "???", "text": "That device basically gives you 5 small momentum boosts, whether you're midair or on the ground."},
		{"name": "???", "text": "Think of them as mini-dashes but once you use up all 5 of them, you can only regain them back when your on the ground."},
		{"name": "???", "text": "Use them to traverse across the upcoming rooms."},
	])

func _on_goal_reached(body):
	if body.is_in_group("Player") and not goal_reached:
		goal_reached = true
		TransitionLayer.play_full_transition("res://Scenes/tutorial_room_4.tscn")
