extends Node2D
var player = null
var goal_reached = false
var skip_canvas: CanvasLayer

func _ready():
	GameManager.is_tutorial = true
	MusicManager.play_for_difficulty("tutorial")
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
	_create_skip_button()


func _create_skip_button():
	skip_canvas = CanvasLayer.new()
	skip_canvas.layer = 50
	add_child(skip_canvas)

	var viewport_size = get_viewport().get_visible_rect().size

	# Build a simple texture for the TouchScreenButton
	var img = Image.create(200, 50, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.15, 0.15, 0.15, 0.85))
	var tex = ImageTexture.create_from_image(img)

	var skip_btn = TouchScreenButton.new()
	skip_btn.texture_normal = tex
	skip_btn.position = Vector2(viewport_size.x - 220, 20)
	skip_btn.pressed.connect(_on_skip_pressed)
	skip_canvas.add_child(skip_btn)

	# Label drawn on top for the text
	var label = Label.new()
	label.text = "Skip Tutorial"
	label.position = Vector2(viewport_size.x - 220, 20)
	label.size = Vector2(200, 50)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font = load("res://Assets/Flexi_IBM_VGA_True.ttf")
	if font:
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 25)
	skip_canvas.add_child(label)

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
		TransitionLayer.play_full_transition("res://Scenes/tutorial_room_2.tscn")
