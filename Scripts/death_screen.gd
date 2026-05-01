extends CanvasLayer

@onready var clipboard = $ClipboardContainer
@onready var score_label = $ClipboardContainer/ScoreLabel
@onready var time_label = $ClipboardContainer/TimeLabel
@onready var rating_label = $ClipboardContainer/RatingLabel
@onready var title_label = $ClipboardContainer/TitleLabel
@onready var menu_button = $ClipboardContainer/MainMenuButton
@onready var restart_button = $ClipboardContainer/RestartButton
@onready var clipboard_image = $ClipboardContainer/ClipboardImage
@onready var submit_btn = $ClipboardContainer/SubmitBtn
@onready var share_btn = $ClipboardContainer/ShareBtn
@onready var status_label = $ClipboardContainer/StatusLabel
@onready var new_best_label = $ClipboardContainer/NewBestLabel

var tween: Tween
var screen_height: float

var run_score : int = 0
var run_rating : String = "B"
var run_time_secs : float = 0

func _ready():
	screen_height = get_viewport().size.y

	for n in [
		score_label, time_label, rating_label,
		title_label, menu_button, restart_button,
		submit_btn, share_btn
	]:
		n.modulate.a = 0

	for n in [
		clipboard_image, score_label, time_label,
		rating_label, title_label,
		menu_button, restart_button,
		submit_btn, share_btn
	]:
		n.position.y += screen_height + 200

	menu_button.pressed.connect(_on_main_menu)
	restart_button.pressed.connect(_on_restart)
	submit_btn.pressed.connect(_submit)
	share_btn.pressed.connect(_share)

	Leaderboard.score_submitted.connect(_on_submitted)

func show_results(score: int, time: float):
	run_score = score
	run_time_secs = time
	run_rating = calculate_rating(score, time)

	var time_string = Leaderboard.format_time(int(time))

	title_label.text = "MISSION FAILED"
	score_label.text = "Score: " + str(score)
	time_label.text = "Time: " + time_string
	rating_label.text = "Rating: " + run_rating

	var is_new_best = SaveData.try_save_run(score, run_rating, int(time))
	new_best_label.visible = is_new_best

	if SaveData.player_name.is_empty():
		submit_btn.disabled = true
		status_label.text = "Set name in menu first."

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)

	var duration = 0.7

	for n in [
		clipboard_image, score_label, time_label,
		rating_label, title_label,
		menu_button, restart_button,
		submit_btn, share_btn
	]:
		tween.tween_property(n, "position:y", n.position.y - screen_height - 200, duration)

	await tween.finished

	var fade = create_tween()
	fade.set_parallel(true)

	for n in [
		title_label, score_label, time_label,
		rating_label, menu_button, restart_button,
		submit_btn, share_btn
	]:
		fade.tween_property(n, "modulate:a", 1.0, 0.3)

func _submit():
	submit_btn.disabled = true
	status_label.text = "Uploading..."
	Leaderboard.submit_score(run_score, run_rating, int(run_time_secs))

func _on_submitted(ok: bool):
	submit_btn.disabled = false
	status_label.text = "Uploaded!" if ok else "Upload failed."

func _share():
	var text = (
		"Just scored %d (%s) in %s on Burst Bound! #BurstBound"
	) % [
		run_score,
		run_rating,
		Leaderboard.format_time(int(run_time_secs))
	]

	OS.shell_open("https://twitter.com/intent/tweet?text=" + text.uri_encode())

func _on_main_menu():
	TransitionLayer.play_full_transition("res://Scenes/main_menu.tscn")
	await TransitionLayer.mid_way
	queue_free()

func _on_restart():
	GameManager.reset_run()
	TransitionLayer.play_full_transition(GameManager.get_random_map())
	await TransitionLayer.mid_way
	queue_free()

func calculate_rating(score: int, time: float) -> String:
	var total = score * 100 - time * 10

	if total >= 800:
		return "S"
	elif total >= 600:
		return "A+"
	elif total >= 400:
		return "A"
	elif total >= 250:
		return "B"
	elif total >= 100:
		return "C"
	else:
		return "D"
