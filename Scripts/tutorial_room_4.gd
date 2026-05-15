extends Node2D

var player = null
var goal_reached = false
var skip_canvas = CanvasLayer

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
	
	_create_skip_button()

func _create_skip_button():
	skip_canvas = CanvasLayer.new()
	skip_canvas.layer = 50
	add_child(skip_canvas)
	
	var skip_btn = Button.new()
	skip_btn.text = "Skip Tutorial"
	skip_btn.anchor_left = 1.0
	skip_btn.anchor_right = 1.0
	skip_btn.anchor_top = 0.0
	skip_btn.anchor_bottom = 0.0
	skip_btn.offset_left = -220
	skip_btn.offset_right = -20
	skip_btn.offset_top = 20
	skip_btn.offset_bottom = 60
	skip_btn.texture_filter = Control.TEXTURE_FILTER_NEAREST
	
	var font = load("res://Assets/Flexi_IBM_VGA_True.ttf")
	if font:
		skip_btn.add_theme_font_override("font", font)
		skip_btn.add_theme_font_size_override("font_size", 25)
	
	skip_btn.pressed.connect(_on_skip_pressed)
	skip_canvas.add_child(skip_btn)
	skip_canvas.visible = false
	
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(skip_canvas):
		skip_canvas.visible = true

func _on_skip_pressed():
	if skip_canvas:
		skip_canvas.queue_free()
	if Dialogue.is_showing:
		Dialogue.end_dialogue()
	GameManager.is_tutorial = false
	GameManager.mark_tutorial_completed()
	TransitionLayer.play_full_transition("res://Scenes/main_menu.tscn")

func _on_goal_reached(body):
	if body.is_in_group("Player") and not goal_reached:
		goal_reached = true
		TransitionLayer.play_full_transition("res://Scenes/tutorial_room_5.tscn")
