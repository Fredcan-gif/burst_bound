extends CanvasLayer

@onready var clipboard = $ClipboardContainer
@onready var score_label = $ClipboardContainer/ScoreLabel
@onready var time_label = $ClipboardContainer/TimeLabel
@onready var rating_label = $ClipboardContainer/RatingLabel
@onready var title_label = $ClipboardContainer/TitleLabel
@onready var menu_button = $ClipboardContainer/MainMenuButton
@onready var restart_button = $ClipboardContainer/RestartButton
@onready var clipboard_image = $ClipboardContainer/ClipboardImage
@onready var leaderboard_container = $ClipboardContainer/LeaderboardContainer
@onready var records_list = $ClipboardContainer/LeaderboardContainer/RecordsList
@onready var leaderboard_title = $ClipboardContainer/LeaderboardContainer/LeaderboardTitle

var tween: Tween
var screen_height: float
var orig_pos = {}
var positions_stored = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	screen_height = get_viewport().size.y
	for child in records_list.get_children():
		child.queue_free()
	orig_pos["clipboard_image"] = clipboard_image.position
	orig_pos["score_label"] = score_label.position
	orig_pos["time_label"] = time_label.position
	orig_pos["rating_label"] = rating_label.position
	orig_pos["title_label"] = title_label.position
	orig_pos["menu_button"] = menu_button.position
	orig_pos["restart_button"] = restart_button.position
	orig_pos["leaderboard_container"] = leaderboard_container.position
	score_label.modulate.a = 0
	time_label.modulate.a = 0
	rating_label.modulate.a = 0
	title_label.modulate.a = 0
	menu_button.modulate.a = 0
	restart_button.modulate.a = 0
	leaderboard_container.modulate.a = 0
	clipboard_image.position.y += screen_height + 200
	score_label.position.y += screen_height + 200
	time_label.position.y += screen_height + 200
	rating_label.position.y += screen_height + 200
	title_label.position.y += screen_height + 200
	menu_button.position.y += screen_height + 200
	restart_button.position.y += screen_height + 200
	leaderboard_container.position.y += screen_height + 200
	menu_button.pressed.connect(_on_main_menu)
	restart_button.pressed.connect(_on_restart)

func show_results(score: int, time: float):
	var rating = calculate_rating(score, time)
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int(fmod(time, 1.0) * 100)
	var time_string = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
	score_label.text = "Score: " + str(score)
	time_label.text = "Time: " + time_string
	rating_label.text = rating
	leaderboard_title.text = "TOP 10"
	GameManager.try_save_best(score, time, rating)
	await NakamaManager.submit_score(GameManager.best_score)
	var records = await NakamaManager.fetch_leaderboard()
	for record in records:
		var label = Label.new()
		label.text = "#%d  %s  —  %d" % [int(record.rank), record.username, int(record.score)]
		label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		records_list.add_child(label)
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	var duration = 0.7
	tween.tween_property(clipboard_image, "position:y", orig_pos["clipboard_image"].y, duration)
	tween.tween_property(score_label, "position:y", orig_pos["score_label"].y, duration)
	tween.tween_property(time_label, "position:y", orig_pos["time_label"].y, duration)
	tween.tween_property(rating_label, "position:y", orig_pos["rating_label"].y, duration)
	tween.tween_property(title_label, "position:y", orig_pos["title_label"].y, duration)
	tween.tween_property(menu_button, "position:y", orig_pos["menu_button"].y, duration)
	tween.tween_property(restart_button, "position:y", orig_pos["restart_button"].y, duration)
	tween.tween_property(leaderboard_container, "position:y", orig_pos["leaderboard_container"].y, duration)
	await tween.finished
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(title_label, "modulate:a", 1.0, 0.3)
	fade_tween.tween_property(score_label, "modulate:a", 1.0, 0.3)
	fade_tween.tween_property(time_label, "modulate:a", 1.0, 0.3)
	fade_tween.tween_property(rating_label, "modulate:a", 1.0, 0.5)
	fade_tween.tween_property(menu_button, "modulate:a", 1.0, 0.3)
	fade_tween.tween_property(restart_button, "modulate:a", 1.0, 0.3)
	fade_tween.tween_property(leaderboard_container, "modulate:a", 1.0, 0.5)

func calculate_rating(score: int, time: float) -> String:
	var score_points = score * 100
	var time_penalty = time * 10
	var total = score_points - time_penalty

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

func _on_main_menu():
	get_tree().paused = false
	TransitionLayer.play_full_transition("res://Scenes/main_menu.tscn")
	await TransitionLayer.mid_way
	queue_free()

func _on_restart():
	GameManager.reset_run()
	get_tree().paused = false
	TransitionLayer.play_full_transition(GameManager.get_random_map())
	await TransitionLayer.mid_way
	queue_free()
