extends Node2D

@onready var camera = $Camera2D
@onready var boss = $Boss
@onready var name_plate = $BossIntroUI/NamePlate
@onready var boss_name_label = $BossIntroUI/BossNameLabel
@onready var intro_sfx = $BossIntroUI/IntroSFX
@onready var boss_name_sub = $BossIntroUI/BossNameSubLabel
@onready var player = $CharacterBody2D
@onready var camera_focus = $Boss/CameraFocus

# Local Boss HP Layer
@onready var boss_hp_layer = $CanvasLayer

var default_camera_zoom: Vector2
var default_camera_pos: Vector2

func _ready():
	# 1. Stop the world
	player.can_move = false
	boss.set_physics_process(false)
	boss.set_process(false)
	get_tree().paused = true

	GameManager.is_tutorial = false
	GameManager.is_boss_intro = true
	MusicManager.play_boss_music(3.0)

	# 2. Hide EVERYTHING for the cinematic
	# Hide Intro UI elements (offset for the slide-in effect)
	for node in [name_plate, boss_name_label, boss_name_sub]:
		node.modulate.a = 0
		node.position.y += 200

	# Hide the Local Boss HP (Local CanvasLayer)
	boss_hp_layer.hide()
	
	if is_instance_valid(GameManager): 
		var timer_ui = GameManager.get_node_or_null("HUDContainer")
		if timer_ui:
			timer_ui.modulate.a = 0

	# Set Text
	boss_name_label.text = "UNIT-CH"
	boss_name_sub.text = "Charging Droid"

	# Capture defaults
	default_camera_zoom = camera.zoom
	default_camera_pos = camera.global_position

	play_boss_intro.call_deferred()

func play_boss_intro():
	await get_tree().process_frame
	
	var boss_target = camera_focus.global_position
	camera.position_smoothing_enabled = false

	# --- PHASE 1: ZOOM IN ---
	var zoom_tween = create_tween().set_parallel(true)
	zoom_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	zoom_tween.set_ease(Tween.EASE_OUT)
	zoom_tween.set_trans(Tween.TRANS_QUART)
	
	zoom_tween.tween_property(camera, "zoom", Vector2(2.5, 2.5), 1.2)
	zoom_tween.tween_property(camera, "global_position", boss_target, 1.2)
	await zoom_tween.finished
	
	# --- PHASE 2: NAME PLATE ---
	intro_sfx.play(0.5)
	var plate_tween = create_tween().set_parallel(true)
	plate_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	plate_tween.set_ease(Tween.EASE_OUT)
	plate_tween.set_trans(Tween.TRANS_BACK)
	
	for node in [name_plate, boss_name_label, boss_name_sub]:
		plate_tween.tween_property(node, "position:y", node.position.y - 200, 0.5)
		plate_tween.tween_property(node, "modulate:a", 1.0, 0.3)
	
	await plate_tween.finished
	
	# Pause to let the player read the name
	await get_tree().create_timer(2.0, true, false, true).timeout
	
	# --- PHASE 3: TWEEN OUT ---
	var slide_out_tween = create_tween().set_parallel(true)
	slide_out_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	slide_out_tween.set_ease(Tween.EASE_IN)
	slide_out_tween.set_trans(Tween.TRANS_BACK)
	
	for node in [name_plate, boss_name_label, boss_name_sub]:
		slide_out_tween.tween_property(node, "position:y", node.position.y + 200, 0.5)
		slide_out_tween.tween_property(node, "modulate:a", 0.0, 0.3)
	
	await slide_out_tween.finished
	
	# Return to gameplay view
	var reset_tween = create_tween().set_parallel(true)
	reset_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reset_tween.set_ease(Tween.EASE_IN_OUT)
	reset_tween.set_trans(Tween.TRANS_QUART)
	
	reset_tween.tween_property(camera, "zoom", default_camera_zoom, 0.8)
	reset_tween.tween_property(camera, "global_position", default_camera_pos, 0.8)
	
	# FADE THE GLOBAL TIMER BACK IN
	if is_instance_valid(GameManager):
		var timer_ui = GameManager.get_node_or_null("HUDContainer")
		if timer_ui:
			reset_tween.tween_property(timer_ui, "modulate:a", 1.0, 0.8)
	
	await reset_tween.finished
	
	# --- PHASE 4: REVEAL HP & START FIGHT ---
	boss_hp_layer.show()
	camera.position_smoothing_enabled = true
	intro_sfx.stop()
	
	# CHECK: Only unpause if the player is actually alive!
	# Replace 'is_dead' with the actual variable name in your player script
	GameManager.is_boss_intro = false
	if player and player.get("is_dead") == false:
		player.can_move = true
		boss.set_physics_process(true)
		boss.set_process(true)
		get_tree().paused = false 
		print("Fight Start: Unpausing")
	else:
		# If the player is dead, keep it paused so the Death UI works
		get_tree().paused = true
		print("Player is dead: Keeping game paused")
