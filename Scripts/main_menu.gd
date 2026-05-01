extends Node2D

@onready var best_rating_label = $Menu/BestRunContainer/BestRatingLabel
@onready var best_score_label  = $Menu/BestRunContainer/BestScoreLabel
@onready var best_time_label   = $Menu/BestRunContainer/BestTimeLabel
@onready var description_label = $Menu/Button_manager/DescriptionLabel

@onready var start_btn     = $Menu/Button_manager/Start
@onready var tutorial_btn  = $Menu/Button_manager/Tutorial
@onready var quit_btn      = $Menu/Button_manager/Quit
@onready var lb_open_btn   = $Menu/Button_manager/Leaderboard

# ── leaderboard UI ──
@onready var lb_panel      = $LeaderboardPanel
@onready var score_list    = $LeaderboardPanel/VBoxContainer/ScoreList
@onready var sort_score_btn= $LeaderboardPanel/SortScore
@onready var sort_time_btn = $LeaderboardPanel/SortTime
@onready var submit_btn    = $LeaderboardPanel/SubmitBtn
@onready var share_btn     = $LeaderboardPanel/ShareBtn
@onready var close_btn     = $LeaderboardPanel/CloseBtn
@onready var status_label  = $LeaderboardPanel/StatusLabel
@onready var name_input    = $LeaderboardPanel/NameInput
@onready var set_name_btn  = $LeaderboardPanel/SetNameBtn

# ─────────────────────────────
# DESCRIPTIONS
# ─────────────────────────────
const DESCRIPTIONS = {
	"start": "Enter the gauntlet. Survive as long as you can.",
	"tutorial": "Learn the basics before diving in.",
	"exit": "Quit the game.",
	"leaderboard": "View top players and your ranking."
}

var _current_entries : Array = []

# ─────────────────────────────
# READY
# ─────────────────────────────
func _ready():
	GameManager.reset_run()
	description_label.text = ""

	_refresh_best_run()
	_connect_signals()

	lb_panel.hide()

	# Nakama signals
	Leaderboard.authenticated.connect(_on_authenticated)
	Leaderboard.scores_loaded.connect(_on_scores_loaded)
	Leaderboard.score_submitted.connect(_on_score_submitted)
	Leaderboard.authenticate()

# ─────────────────────────────
# BEST RUN DISPLAY
# ─────────────────────────────
func _refresh_best_run():
	if GameManager.best_rating == "":
		best_rating_label.text = "—"
		best_score_label.text = "—"
		best_time_label.text = "—"
	else:
		var t = GameManager.best_time
		var time_string = "%02d:%02d.%02d" % [
			int(t) / 60,
			int(t) % 60,
			int(fmod(t, 1.0) * 100)
		]

		best_rating_label.text = GameManager.best_rating
		best_score_label.text  = str(GameManager.best_score)
		best_time_label.text   = time_string

func _connect_signals():

	start_btn.pressed.connect(_on_start_pressed)
	tutorial_btn.pressed.connect(_on_tutorial_pressed)
	quit_btn.pressed.connect(get_tree().quit)
	lb_open_btn.pressed.connect(_open_leaderboard)

	start_btn.mouse_entered.connect(func(): description_label.text = DESCRIPTIONS["start"])
	start_btn.mouse_exited.connect(func(): description_label.text = "")

	tutorial_btn.mouse_entered.connect(func(): description_label.text = DESCRIPTIONS["tutorial"])
	tutorial_btn.mouse_exited.connect(func(): description_label.text = "")

	quit_btn.mouse_entered.connect(func(): description_label.text = DESCRIPTIONS["exit"])
	quit_btn.mouse_exited.connect(func(): description_label.text = "")

	lb_open_btn.mouse_entered.connect(func(): description_label.text = DESCRIPTIONS["leaderboard"])
	lb_open_btn.mouse_exited.connect(func(): description_label.text = "")

	sort_score_btn.pressed.connect(func(): _fetch("score"))
	sort_time_btn.pressed.connect(func(): _fetch("time_secs"))
	submit_btn.pressed.connect(_submit)
	share_btn.pressed.connect(_share)
	close_btn.pressed.connect(lb_panel.hide)
	set_name_btn.pressed.connect(_set_name)

func _on_start_pressed():
	GameManager.score = 0
	var first_map = GameManager.get_random_map()
	TransitionLayer.play_full_transition(first_map)

func _on_tutorial_pressed():
	TransitionLayer.play_full_transition("res://Scenes/tutorial_room_1.tscn")

func _open_leaderboard():
	lb_panel.show()
	name_input.text = SaveData.player_name
	_fetch("score")

func _fetch(sort_by: String):
	_clear_list()
	status_label.text = "Loading..."
	Leaderboard.fetch_top_scores(sort_by)

func _submit():
	if SaveData.player_name.is_empty():
		status_label.text = "Set your name first."
		return

	submit_btn.disabled = true
	status_label.text = "Submitting..."

	Leaderboard.submit_score(
		GameManager.best_score,
		GameManager.best_rating,
		GameManager.best_time
	)

func _set_name():
	var n = name_input.text.strip_edges()
	if n.is_empty():
		return

	SaveData.set_player_name(n)
	status_label.text = "Name saved: " + n

func _share():
	var rank = _find_my_rank()
	var time_str = Leaderboard.format_time(GameManager.best_time)

	var text = (
		"I ranked #%d on Burst Bound! Score: %d | Rating: %s | Time: %s #BurstBound"
	) % [rank, GameManager.best_score, GameManager.best_rating, time_str]

	OS.shell_open("https://twitter.com/intent/tweet?text=" + text.uri_encode())

func _on_authenticated(ok: bool):
	if not ok:
		status_label.text = "Server connection failed."

func _on_scores_loaded(entries: Array):
	_current_entries = entries
	_clear_list()

	if entries.is_empty():
		status_label.text = "No scores yet!"
		return

	for e in entries:
		var row = Label.new()
		var time_str = Leaderboard.format_time(e.get("time_secs", 0))
		var rank = int(e.get("rank", 99))
		var medal = ["🥇","🥈","🥉"][rank - 1] if rank <= 3 else ""

		row.text = "%s #%d %s - %d pts | %s | %s" % [
			medal,
			e.get("rank", 0),
			e.get("player", "???"),
			e.get("score", 0),
			e.get("rating", "-"),
			time_str
		]

		score_list.add_child(row)

func _on_score_submitted(ok: bool):
	submit_btn.disabled = false
	status_label.text = "Uploaded!" if ok else "Failed!"

	if ok:
		_fetch("score")

func _find_my_rank() -> int:
	for e in _current_entries:
		if e.get("player", "") == SaveData.player_name:
			return int(e.get("rank", 0))
	return _current_entries.size() + 1

func _clear_list():
	for child in score_list.get_children():
		child.queue_free()
