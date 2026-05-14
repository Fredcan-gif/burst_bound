extends Node2D

var player = null
var collapse_triggered = false

@onready var collapse_zone = $CollapseZone
@onready var collapse_platform = $CollapsePlatform
@onready var camera = $Camera2D
@onready var collapse_sfx = $CollapseSFX

func _ready():
	GameManager.is_tutorial = true
	player = get_tree().get_first_node_in_group("Player")
	player.can_jump = true
	player.can_dash = false
	
	collapse_zone.body_entered.connect(_on_collapse_triggered)
	
	Dialogue.start_dialogue([
		{"name": "???", "text": "Well done, you have far exceeded our expectations!"},
		{"name": "You", "text": "Can you finally let me free now?"},
		{"name": "???", "text": "As promised, the exit is right up ahead."},
	])

func _on_collapse_triggered(body):
	if body.is_in_group("Player") and not collapse_triggered:
		collapse_triggered = true
		start_collapse()

func start_collapse():
	player.can_move = false
	
	# Shake platform before falling
	var shake_tween = create_tween()
	shake_tween.set_loops(4)
	shake_tween.tween_property(collapse_platform, "position:x", collapse_platform.position.x + 4, 0.05)
	shake_tween.tween_property(collapse_platform, "position:x", collapse_platform.position.x - 4, 0.05)
	await shake_tween.finished
	
	collapse_platform.position.x = 0
	
	# Play sound and drop platform at the same time
	collapse_sfx.play()
	screen_shake()
	
	var fall_tween = create_tween()
	fall_tween.set_ease(Tween.EASE_IN)
	fall_tween.set_trans(Tween.TRANS_QUAD)
	fall_tween.tween_property(collapse_platform, "position:y", collapse_platform.position.y + 1000, 0.5)
	await fall_tween.finished
	
	Dialogue.start_dialogue([
		{"name": "???", "text": "Unfortunately, your work has exceeded our expectations TOO well."},
		{"name": "???", "text": "It would be a waste to let you go so early."},
		{"name": "???", "text": "We could reap the benefits more if you stay here longer."},
		{"name": "You", "text": "Where am I? I can't see anything! You promised!"},
		{"name": "???", "text": "Change of plans, your going to have to stay here a bit longer..."},
		{"name": " ", "text": "You slowly slip away from consciousness as the pitch darkness envelops you."},
	])
	await Dialogue.dialogue_finished
	
	GameManager.is_tutorial = false
	GameManager.mark_tutorial_completed()
	TransitionLayer.play_full_transition("res://Scenes/main_menu.tscn")

func screen_shake():
	var shake_duration = 0.4
	var shake_strength = 6.0
	var elapsed = 0.0
	
	while elapsed < shake_duration:
		camera.offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	
	camera.offset = Vector2.ZERO
