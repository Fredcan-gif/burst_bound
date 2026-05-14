extends CanvasLayer

@onready var clipboard = $ClipboardContainer
@onready var score_label = $ClipboardContainer/ScoreLabel
@onready var title_label = $ClipboardContainer/TitleLabel
@onready var menu_button = $ClipboardContainer/MainMenuButton
@onready var resume_button = $ClipboardContainer/ResumeButton
@onready var settings_button = $ClipboardContainer/SettingsButton
@onready var clipboard_image = $ClipboardContainer/ClipboardImage
@onready var black_overlay = $BlackOverlay

@onready var quit_confirm_popup = $QuitConfirmPopup
@onready var confirm_yes = $QuitConfirmPopup/ConfirmYes
@onready var confirm_no = $QuitConfirmPopup/ConfirmNo

var tween: Tween
var screen_height: float
var orig_pos = {}

func _ready():
	screen_height = get_viewport().size.y
	
	black_overlay.modulate.a = 0
	quit_confirm_popup.hide()
	
	orig_pos["clipboard_image"] = clipboard_image.position
	orig_pos["score_label"] = score_label.position
	orig_pos["title_label"] = title_label.position
	orig_pos["menu_button"] = menu_button.position
	orig_pos["resume_button"] = resume_button.position
	orig_pos["settings_button"] = settings_button.position

	score_label.modulate.a = 0
	menu_button.modulate.a = 0
	resume_button.modulate.a = 0
	settings_button.modulate.a = 0

	clipboard_image.position.y += screen_height + 200
	score_label.position.y += screen_height + 200
	title_label.position.y += screen_height + 200
	menu_button.position.y += screen_height + 200
	resume_button.position.y += screen_height + 200
	settings_button.position.y += screen_height + 200

	menu_button.pressed.connect(_on_main_menu)
	resume_button.pressed.connect(_on_resume)
	settings_button.pressed.connect(_on_settings)
	confirm_yes.pressed.connect(_on_confirm_quit)
	confirm_no.pressed.connect(func(): quit_confirm_popup.hide())
	
	hide()

func _input(event):
	if event.is_action_pressed("ui_cancel") and GameManager.game_started and not GameManager.player_dead:
		# Don't unpause if options popup or confirm popup is open
		if get_node_or_null("Options") != null or quit_confirm_popup.visible:
			return
			
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()

func _pause_game():
	get_tree().paused = true
	show()
	
	score_label.text = "Score: " + str(GameManager.score)
	
	# Set all alphas to 1 immediately
	score_label.modulate.a = 1.0
	menu_button.modulate.a = 1.0
	resume_button.modulate.a = 1.0
	settings_button.modulate.a = 1.0
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_parallel(true)
	var duration = 0.7

	tween.tween_property(clipboard_image, "position:y", orig_pos["clipboard_image"].y, duration)
	tween.tween_property(score_label, "position:y", orig_pos["score_label"].y, duration)
	tween.tween_property(title_label, "position:y", orig_pos["title_label"].y, duration)
	tween.tween_property(menu_button, "position:y", orig_pos["menu_button"].y, duration)
	tween.tween_property(resume_button, "position:y", orig_pos["resume_button"].y, duration)
	tween.tween_property(settings_button, "position:y", orig_pos["settings_button"].y, duration)
	tween.tween_property(black_overlay, "modulate:a", 1.0, duration)
	
	await tween.finished

func _resume_game():
	get_tree().paused = false
	hide()
	
	clipboard_image.position.y = orig_pos["clipboard_image"].y + screen_height + 200
	score_label.position.y = orig_pos["score_label"].y + screen_height + 200
	title_label.position.y = orig_pos["title_label"].y + screen_height + 200
	menu_button.position.y = orig_pos["menu_button"].y + screen_height + 200
	resume_button.position.y = orig_pos["resume_button"].y + screen_height + 200
	settings_button.position.y = orig_pos["settings_button"].y + screen_height + 200
	
	score_label.modulate.a = 0
	menu_button.modulate.a = 0
	resume_button.modulate.a = 0
	settings_button.modulate.a = 0
	black_overlay.modulate.a = 0
	quit_confirm_popup.hide()

func _on_main_menu():
	quit_confirm_popup.show()

func _on_confirm_quit():
	quit_confirm_popup.hide()
	_resume_game()
	GameManager.reset_run()
	MusicManager.reset_to_menu()
	TransitionLayer.play_full_transition("res://Scenes/main_menu.tscn")

func _on_resume():
	_resume_game()

func _on_settings():
	var options = load("res://Scenes/options.tscn").instantiate()
	options.set_meta("is_popup", true)
	options.name = "Options"
	add_child(options)
	if options.has_node("Background"):
		options.get_node("Background").layer = 5
