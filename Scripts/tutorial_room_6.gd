extends Node2D

var player = null
var goal_reached = false

func _ready():
	GameManager.is_tutorial = true
	player = get_tree().get_first_node_in_group("Player")
	player.can_jump = true
	player.can_dash = true
	$TutorialExit.body_entered.connect(_on_goal_reached)

func _on_goal_reached(body):
	if body.is_in_group("Player") and not goal_reached:
		goal_reached = true
		TransitionLayer.play_full_transition("res://Scenes/tutorial_room_end.tscn")
