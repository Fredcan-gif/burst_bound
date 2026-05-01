extends Node2D

<<<<<<< HEAD
# ── existing nodes ────────────────────────────
@onready var best_rating_label : Label = $Menu/BestRunContainer/BestRatingLabel
@onready var best_score_label  : Label = $Menu/BestRunContainer/BestScoreLabel
@onready var best_time_label   : Label = $Menu/BestRunContainer/BestTimeLabel
=======
@onready var best_rating_label = $BestRunContainer/RatingRow/BestRatingLabel
@onready var best_score_label = $BestRunContainer/ScoreRow/BestScoreLabel
@onready var best_time_label = $BestRunContainer/TimeRow/BestTimeLabel
>>>>>>> e134ab6 (Added training stage and updated main menu)

# ── leaderboard panel ─────────────────────────
# Add a CanvasLayer > Panel named "LeaderboardPanel" to your scene,
# then add the following children inside it:
#   VBoxContainer/ScoreList   (VBoxContainer)
#   SortScore                 (Button)  label: "Top Score"
#   SortTime                  (Button)  label: "Best Time"
#   SubmitBtn                 (Button)  label: "Submit My Score"
#   ShareBtn                  (Button)  label: "Share on X"
#   CloseBtn                  (Button)  label: "✕"
#   StatusLabel               (Label)
#   NameInput                 (LineEdit) placeholder: "Enter your name"
#   SetNameBtn                (Button)  label: "Set Name"
# Also add a "Leaderboard" Button inside your existing Button_manager.

@onready var lb_panel       : CanvasLayer   = $LeaderboardPanel
@onready var score_list     : VBoxContainer = $LeaderboardPanel/VBoxContainer/ScoreList
@onready var sort_score_btn : Button        = $LeaderboardPanel/SortScore
@onready var sort_time_btn  : Button        = $LeaderboardPanel/SortTime
@onready var submit_btn     : Button        = $LeaderboardPanel/SubmitBtn
@onready var share_btn      : Button        = $LeaderboardPanel/ShareBtn
@onready var close_btn      : Button        = $LeaderboardPanel/CloseBtn
@onready var status_label   : Label         = $LeaderboardPanel/StatusLabel
@onready var name_input     : LineEdit      = $LeaderboardPanel/NameInput
@onready var set_name_btn   : Button        = $LeaderboardPanel/SetNameBtn
@onready var lb_open_btn    : Button        = $Menu/Button_manager/Leaderboard

var _current_entries : Array = []


func _ready() -> void:
	# ── your original logic ──
	GameManager.reset_run()
<<<<<<< HEAD
	BackgroundMusic.change_music(preload("res://Assets/bransboynd-industrial-work-389650.mp3"))
	_refresh_best_run()

	# ── leaderboard setup ──
	lb_panel.hide()
	_connect_signals()
	Leaderboard.authenticated.connect(_on_authenticated)
	Leaderboard.scores_loaded.connect(_on_scores_loaded)
	Leaderboard.score_submitted.connect(_on_score_submitted)
	Leaderboard.authenticate()


# ── best run display ──────────────────────────

func _refresh_best_run() -> void:
	if GameManager.best_rating == "":
		best_rating_label.text = "Best Rating: —"
		best_score_label.text  = "Best Score: —"
		best_time_label.text   = "Best Time: —"
	else:
		var t : float = GameManager.best_time
		var time_string := "%02d:%02d.%02d" % [int(t) / 60, int(t) % 60, int(fmod(t, 1.0) * 100)]
		best_rating_label.text = "Best Rating: " + GameManager.best_rating
		best_score_label.text  = "Best Score: "  + str(GameManager.best_score)
		best_time_label.text   = "Best Time: "   + time_string


# ── button signals ────────────────────────────

func _connect_signals() -> void:
	lb_open_btn.pressed.connect(_open_leaderboard)
	sort_score_btn.pressed.connect(func(): _fetch("score"))
	sort_time_btn.pressed.connect(func(): _fetch("time_secs"))
	submit_btn.pressed.connect(_submit)
	share_btn.pressed.connect(_share)
	close_btn.pressed.connect(lb_panel.hide)
	set_name_btn.pressed.connect(_set_name)


# ── your original button handlers ─────────────

func _on_quit_pressed() -> void:
=======
		
	if GameManager.best_rating == "":
		best_rating_label.text = "—"
		best_score_label.text = "—"
		best_time_label.text = "—"
	else:
		var t = GameManager.best_time
		var time_string = "%02d:%02d.%02d" % [int(t) / 60, int(t) % 60, int(fmod(t, 1.0) * 100)]
		best_rating_label.text = GameManager.best_rating
		best_score_label.text = str(GameManager.best_score)
		best_time_label.text = time_string
				
func _on_quit_pressed():
>>>>>>> e134ab6 (Added training stage and updated main menu)
	get_tree().quit()


func _on_start_pressed() -> void:
	GameManager.score = 0
	var first_map = GameManager.get_random_map()
	TransitionLayer.play_full_transition(first_map)
<<<<<<< HEAD


# ── nakama callbacks ──────────────────────────

func _on_authenticated(ok: bool) -> void:
	if not ok:
		status_label.text = "Could not reach leaderboard server."


func _on_scores_loaded(entries: Array) -> void:
	_current_entries = entries
	_clear_list()
	status_label.text = ""

	if entries.is_empty():
		status_label.text = "No scores yet — be the first!"
		return

	for e in entries:
		var row      := Label.new()
		var time_str : String = Leaderboard.format_time(e.get("time_secs", 0))
		var rank_idx : int = int(e.get("rank", 99)) - 1
		var medal    : String = ["🥇", "🥈", "🥉"][rank_idx] if rank_idx < 3 else "  "
		row.text = "%s #%-3d %-16s %6d pts  %s  %s" % [
			medal,
			e.get("rank", 0),
			e.get("player", "???"),
			e.get("score", 0),
			e.get("rating", "-"),
			time_str
		]
		row.add_theme_font_size_override("font_size", 14)
		score_list.add_child(row)


func _on_score_submitted(ok: bool) -> void:
	submit_btn.disabled = false
	status_label.text   = "Uploaded!" if ok else "Upload failed — try again."
	if ok:
		_fetch("score")


# ── leaderboard actions ───────────────────────

func _open_leaderboard() -> void:
	lb_panel.show()
	name_input.text = SaveData.player_name
	_fetch("score")


func _fetch(sort_by: String) -> void:
	_clear_list()
	status_label.text = "Loading…"
	Leaderboard.fetch_top_scores(sort_by)


func _submit() -> void:
	if SaveData.player_name.is_empty():
		status_label.text = "Set your name first."
		return
	submit_btn.disabled = true
	status_label.text   = "Submitting…"
	var time_secs := int(GameManager.best_time)
	Leaderboard.submit_score(
		GameManager.best_score,
		GameManager.best_rating,
		time_secs
	)


func _set_name() -> void:
	var n := name_input.text.strip_edges()
	if n.is_empty():
		return
	SaveData.set_player_name(n)
	status_label.text = "Name saved: " + n


func _share() -> void:
	var rank     := _find_my_rank()
	var t : float = GameManager.best_time
	var time_str := "%02d:%02d.%02d" % [int(t) / 60, int(t) % 60, int(fmod(t, 1.0) * 100)]
	var text     := (
		"I ranked #%d on Burst Bound! "
		+ "Score: %d | Rating: %s | Time: %s "
		+ "#BurstBound #indiegame"
	) % [rank, GameManager.best_score, GameManager.best_rating, time_str]
	OS.shell_open("https://twitter.com/intent/tweet?text=" + text.uri_encode())


func _find_my_rank() -> int:
	for e in _current_entries:
		if e.get("player", "") == SaveData.player_name:
			return int(e.get("rank", 0))
	return _current_entries.size() + 1


func _clear_list() -> void:
	for child in score_list.get_children():
		child.queue_free()
=======
	
func _on_tutorial_pressed() -> void:
	TransitionLayer.play_full_transition("res://Scenes/tutorial_room_1.tscn")
>>>>>>> e134ab6 (Added training stage and updated main menu)
