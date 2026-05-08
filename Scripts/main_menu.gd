extends Node2D

@onready var best_rating_label = $BestRunContainer/RatingRow/BestRatingLabel
@onready var best_score_label = $BestRunContainer/ScoreRow/BestScoreLabel
@onready var best_time_label = $BestRunContainer/TimeRow/BestTimeLabel
@onready var description_label = $Menu/Button_manager/DescriptionLabel
@onready var records_list = $LeaderboardContainer/RecordsList

const DESCRIPTIONS = {
	"start": "Survive and traverse through endless rooms and bosses. Each stage becomes increasingly difficult.",
	"tutorial": "Get to know the controls of the experiment.",
	"exit": "Exit the experiment."
}

const RATING_COLORS = {
	"S":  Color(1.0, 0.84, 0.0),
	"A+": Color(0.0, 1.0, 0.5),
	"A":  Color(0.4, 0.9, 0.4),
	"B":  Color(0.4, 0.7, 1.0),
	"C":  Color(1.0, 0.8, 0.3),
	"D":  Color(0.8, 0.4, 0.4),
}

const MEDAL_COLORS = {
	0: Color(1.0, 0.84, 0.0),
	1: Color(0.75, 0.75, 0.75),
	2: Color(0.8, 0.5, 0.2),
}

func _ready():
	GameManager.reset_run()
	description_label.text = ""

	$Menu/Button_manager/Start.mouse_entered.connect(func(): description_label.text = DESCRIPTIONS["start"])
	$Menu/Button_manager/Start.mouse_exited.connect(func(): description_label.text = "")
	$Menu/Button_manager/Tutorial.mouse_entered.connect(func(): description_label.text = DESCRIPTIONS["tutorial"])
	$Menu/Button_manager/Tutorial.mouse_exited.connect(func(): description_label.text = "")
	$Menu/Button_manager/Quit.mouse_entered.connect(func(): description_label.text = DESCRIPTIONS["exit"])
	$Menu/Button_manager/Quit.mouse_exited.connect(func(): description_label.text = "")

	if GameManager.best_rating == "":
		best_rating_label.text = "—"
		best_score_label.text = "—"
		best_time_label.text = "—"
	else:
		var t = GameManager.best_time
		var time_string = "%02d:%02d.%02d" % [int(t / 60.0), int(t) % 60, int(fmod(t, 1.0) * 100)]
		best_rating_label.text = GameManager.best_rating
		best_score_label.text = str(GameManager.best_score)
		best_time_label.text = time_string

	_populate_leaderboard()

func _populate_leaderboard():
	for child in records_list.get_children():
		child.queue_free()

	var records = GameManager.get_top_records()

	if records.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No records yet!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		records_list.add_child(empty_label)
		return

	for i in range(min(records.size(), 10)):
		var record = records[i]
		var row = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)

		# Rank
		var rank_lbl = Label.new()
		rank_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rank_lbl.custom_minimum_size.x = 28
		rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if i < 3:
			rank_lbl.text = ["🥇", "🥈", "🥉"][i]
		else:
			rank_lbl.text = "#" + str(i + 1)
			rank_lbl.modulate = Color(0.7, 0.7, 0.7)
		row.add_child(rank_lbl)

		# Separator
		var sep = VSeparator.new()
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sep.modulate = Color(0.5, 0.5, 0.5, 0.5)
		row.add_child(sep)

		# Score
		var score_lbl = Label.new()
		score_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		score_lbl.text = str(record.get("score", 0))
		score_lbl.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if i == 0:
			score_lbl.modulate = MEDAL_COLORS[0]
		row.add_child(score_lbl)

		# Time
		var t = record.get("time", 0.0)
		var time_lbl = Label.new()
		time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		time_lbl.text = "%02d:%02d.%02d" % [int(t / 60.0), int(t) % 60, int(fmod(t, 1.0) * 100)]
		time_lbl.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_lbl.modulate = Color(0.8, 0.9, 1.0)
		row.add_child(time_lbl)

		# Rating
		var rating_str = record.get("rating", "D")
		var rating_lbl = Label.new()
		rating_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rating_lbl.text = rating_str
		rating_lbl.custom_minimum_size.x = 30
		rating_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if rating_str in RATING_COLORS:
			rating_lbl.modulate = RATING_COLORS[rating_str]
		row.add_child(rating_lbl)

		records_list.add_child(row)

func _on_quit_pressed():
	get_tree().quit()

func _on_start_pressed() -> void:
	GameManager.score = 0
	MusicManager.play_for_difficulty("easy")
	var first_map = GameManager.get_next_map()
	TransitionLayer.play_full_transition(first_map)

func _on_tutorial_pressed() -> void:
	TransitionLayer.play_full_transition("res://Scenes/tutorial_room_1.tscn")
