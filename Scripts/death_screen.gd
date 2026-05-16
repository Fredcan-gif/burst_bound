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
@onready var records_list = $ClipboardContainer/LeaderboardContainer/LeaderboardScroll/RecordsList
@onready var leaderboard_title = $ClipboardContainer/LeaderboardContainer/LeaderboardTitle
@onready var leaderboard_scroll = $ClipboardContainer/LeaderboardContainer/LeaderboardScroll
@onready var black_overlay = $BlackOverlay

var tween: Tween
var screen_height: float
var orig_pos = {}

const MEDAL_COLORS = {
	0: Color(1.0, 0.84, 0.0),
	1: Color(0.75, 0.75, 0.75),
	2: Color(0.8, 0.5, 0.2),
}

const RATING_COLORS = {
	"S":  Color(1.0, 0.84, 0.0),
	"A+": Color(0.0, 1.0, 0.5),
	"A":  Color(0.4, 0.9, 0.4),
	"B":  Color(0.079, 0.341, 1.0, 1.0),
	"C":  Color(1.0, 0.8, 0.3),
	"D":  Color(0.939, 0.0, 0.0, 1.0),
}

func _ready():
	screen_height = get_viewport().size.y
	for child in records_list.get_children():
		child.queue_free()
		
	black_overlay.modulate.a = 0
	
	leaderboard_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	leaderboard_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	leaderboard_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS # Or SCROLL_MODE_SHOW_AS_NEEDED
	
	# Enable touch drag scrolling
	leaderboard_scroll.get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE
	
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
	var time_string = _format_time(time)

	score_label.text = "Score: " + str(score)
	time_label.text = "Time: " + time_string
	rating_label.text = rating
	leaderboard_title.text = "— TOP RECORDS —"

	if rating in RATING_COLORS:
		var c = RATING_COLORS[rating]
		rating_label.modulate = Color(c.r, c.g, c.b, 0.0)

	GameManager.try_save_best(score, time, rating)
	_populate_leaderboard()

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
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
	tween.tween_property(black_overlay, "modulate:a", 1.0, duration)

	await tween.finished
	_animate_leaderboard_rows()

	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(score_label, "modulate:a", 1.0, 0.3)
	fade_tween.tween_property(time_label, "modulate:a", 1.0, 0.3)
	fade_tween.tween_property(rating_label, "modulate:a", 1.0, 0.5)
	fade_tween.tween_property(menu_button, "modulate:a", 1.0, 0.3)
	fade_tween.tween_property(restart_button, "modulate:a", 1.0, 0.3)
	fade_tween.tween_property(leaderboard_container, "modulate:a", 1.0, 0.5)

func _populate_leaderboard():
	leaderboard_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	for child in records_list.get_children():
		child.queue_free()

	var records = GameManager.get_top_records()

	if records.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No records yet!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
		records_list.add_child(empty_label)
		return

	for i in range(min(records.size(), 10)):
		var record = records[i]
		var row = _create_leaderboard_row(i, record)
		row.modulate.a = 0
		records_list.add_child(row)

func _create_leaderboard_row(index: int, record: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	row.add_theme_constant_override("separation", 6)

	var is_new = GameManager.is_latest_record(index)
	if is_new:
		var bg = ColorRect.new()
		bg.color = Color(1.0, 1.0, 0.5, 0.12)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_child(bg)
		row.move_child(bg, 0)

	# Rank label
	var rank_label = Label.new()
	rank_label.custom_minimum_size.x = 28
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if index < 3:
		rank_label.text = ["🥇", "🥈", "🥉"][index]
	else:
		rank_label.text = "#" + str(index + 1)
		rank_label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
	row.add_child(rank_label)

	# Separator
	var sep = VSeparator.new()
	sep.modulate = Color(0.5, 0.5, 0.5, 0.5)
	row.add_child(sep)

	# Score
	var score_lbl = Label.new()
	score_lbl.text = str(record.get("score", 0))
	score_lbl.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if index == 0:
		score_lbl.add_theme_color_override("font_color", MEDAL_COLORS[0])
	else:
		score_lbl.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
	row.add_child(score_lbl)

	# Time
	var time_lbl = Label.new()
	time_lbl.text = _format_time(record.get("time", 0.0))
	time_lbl.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_lbl.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
	row.add_child(time_lbl)

	# Rating
	var rating_str = record.get("rating", "D")
	var rating_lbl = Label.new()
	rating_lbl.text = rating_str
	rating_lbl.custom_minimum_size.x = 30
	rating_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if rating_str in RATING_COLORS:
		rating_lbl.add_theme_color_override("font_color", RATING_COLORS[rating_str])
	row.add_child(rating_lbl)

	# NEW badge
	if is_new:
		var new_lbl = Label.new()
		new_lbl.text = "NEW"
		new_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		new_lbl.custom_minimum_size.x = 36
		new_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(new_lbl)

	return row

func _animate_leaderboard_rows():
	var rows = records_list.get_children()
	for i in range(rows.size()):
		var row = rows[i]
		var delay = i * 0.06
		var row_tween = create_tween()
		row_tween.tween_interval(delay)
		row_tween.tween_property(row, "modulate:a", 1.0, 0.2)

func _format_time(time: float) -> String:
	var minutes = int(time / 60.0)
	var seconds = int(time) % 60
	var milliseconds = int(fmod(time, 1.0) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func calculate_rating(score: int, time: float) -> String:
	var score_points = score * 100
	var time_penalty = time * 10
	var total = score_points - time_penalty
	if total >= 2000:
		return "S"
	elif total >= 1500:
		return "A+"
	elif total >= 900:
		return "A"
	elif total >= 500:
		return "B"
	elif total >= 200:
		return "C"
	else:
		return "D"

func _on_main_menu():
	MusicManager.reset_to_menu()
	get_tree().paused = false
	TransitionLayer.play_full_transition("res://Scenes/main_menu.tscn")
	await TransitionLayer.mid_way
	queue_free()

func _on_restart():
	GameManager.reset_run()
	MusicManager.reset()
	MusicManager.play_for_difficulty(GameManager.current_difficulty)
	get_tree().paused = false
	TransitionLayer.play_full_transition(GameManager.get_next_map())
	await TransitionLayer.mid_way
	queue_free()
