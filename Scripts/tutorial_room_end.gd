extends Node2D

var player = null
var collapse_triggered = false

@onready var collapse_zone = $CollapseZone
@onready var collapse_platform = $CollapsePlatform
@onready var platform_body = $CollapsePlatform/StaticBody2D

func _ready():
	GameManager.is_tutorial = true
	player = get_tree().get_first_node_in_group("Player")
	
	# Only walking allowed
	player.can_jump = false
	player.can_dash = false
	player.camera.enabled = true
	
	collapse_zone.body_entered.connect(_on_collapse_triggered)
	
	Dialogue.start_dialogue([
		{"name": "???", "text": "Walk forward."},
	])

func _on_collapse_triggered(body):
	if body.is_in_group("Player") and not collapse_triggered:
		collapse_triggered = true
		collapse_zone.monitoring = false
		start_collapse()

func start_collapse():
	# Lock player
	player.can_move = false
	
	# Shake the platform before it falls
	var tween = create_tween()
	tween.set_loops(5)
	tween.tween_property(collapse_platform, "position:x", collapse_platform.position.x + 3, 0.05)
	tween.tween_property(collapse_platform, "position:x", collapse_platform.position.x - 3, 0.05)
	await tween.finished
	
	# Drop the platform
	var fall_tween = create_tween()
	fall_tween.set_ease(Tween.EASE_IN)
	fall_tween.set_trans(Tween.TRANS_QUAD)
	fall_tween.tween_property(collapse_platform, "position:y", collapse_platform.position.y + 400, 0.6)
	await fall_tween.finished
	
	# Dialogue after collapse
	player.can_move = false
	Dialogue.start_dialogue([
		{"name": "???", "text": "The ground beneath you gave way."},
		{"name": "???", "text": "Nothing here is permanent. Stay alert."},
		{"name": "???", "text": "You are ready."},
	])
	await Dialogue.dialogue_finished
	
	GameManager.is_tutorial = false
	TransitionLayer.play_full_transition("res://Scenes/main_menu.tscn")
