extends Node

var score = 0
var stages_completed = 0
var current_difficulty = "easy"
var boss_count = 0

var easy_maps = [
	"res://Scenes/level_easy_1.tscn",
	"res://Scenes/level_easy_2.tscn",
	"res://Scenes/level_easy_3.tscn",
	"res://Scenes/level_easy_4.tscn",
	"res://Scenes/level_easy_5.tscn",
]
var medium_maps = [
	"res://Scenes/level_medium_1.tscn",
	"res://Scenes/level_medium_2.tscn",
	"res://Scenes/level_medium_3.tscn",
	"res://Scenes/level_medium_4.tscn",
]
var hard_maps = [
	"res://Scenes/level_hard_1.tscn",
	"res://Scenes/level_hard_2.tscn",
	"res://Scenes/level_hard_3.tscn",
]
var remaining_maps = []

# Timer
var level_time = 0.0
var timer_running = false
var game_started = false
var player_dead = false
var is_tutorial = false
var tutorial_completed = false
var is_boss_intro = false

# Best run (kept for main menu display)
var best_score = 0
var best_time = 0.0
var best_rating = ""

# Leaderboard — array of {score, time, rating}, max 10 entries
const MAX_RECORDS = 10
var leaderboard: Array = []
var latest_record_index: int = -1  # Which rank the most recent run landed on

func _ready():
	refill_map_pool()
	load_best()
	load_leaderboard()
	load_settings_on_start()
	load_progress()
	
func _start_music():
	MusicManager.play_for_difficulty("easy")
	
func start_tutorial_music():
	is_tutorial = true
	MusicManager.play_for_difficulty("tutorial")
	
func _process(delta):
	if timer_running:
		level_time += delta

# ─── Map logic ────────────────────────────────────────────────────────────────

func get_current_pool() -> Array:
	match current_difficulty:
		"easy":   return easy_maps
		"medium": return medium_maps
		"hard":   return hard_maps
	return easy_maps

func refill_map_pool():
	remaining_maps = get_current_pool().duplicate()
	remaining_maps.shuffle()

func get_next_map() -> String:
	if stages_completed > 0 and stages_completed % 10 == 0:
		return "res://Scenes/boss_stage_1.tscn"
	if remaining_maps.is_empty():
		refill_map_pool()
	return remaining_maps.pop_back()

func complete_stage():
	stages_completed += 1
	print("Stages completed: ", stages_completed)
	if stages_completed % 10 == 0:
		advance_difficulty()

func advance_difficulty():
	match current_difficulty:
		"easy":
			current_difficulty = "medium"
			MusicManager.play_for_difficulty("medium")
		"medium":
			current_difficulty = "hard"
			MusicManager.play_for_difficulty("hard")
		"hard":
			print("Already at max difficulty")
	refill_map_pool()

func add_point():
	score += 1
	print("Current Score: ", score)

func start_level_timer():
	if game_started:
		return
	game_started = true
	level_time = 0.0
	timer_running = true

func stop_level_timer():
	timer_running = false
	game_started = false

# ─── Rating helpers ───────────────────────────────────────────────────────────

const RATING_RANK = {"D": 0, "C": 1, "B": 2, "A": 3, "A+": 4, "S": 5}

func _compare_records(a: Dictionary, b: Dictionary) -> bool:
	# Returns true if 'a' is strictly better than 'b'
	var ra = RATING_RANK.get(a.get("rating", "D"), 0)
	var rb = RATING_RANK.get(b.get("rating", "D"), 0)
	if ra != rb:
		return ra > rb
	if a.get("score", 0) != b.get("score", 0):
		return a.get("score", 0) > b.get("score", 0)
	return a.get("time", 9999.0) < b.get("time", 9999.0)

# ─── Save / load best run (legacy, used by main menu) ────────────────────────

func try_save_best(run_score: int, run_time: float, run_rating: String):
	if is_tutorial:
		return

	# Update legacy single-best for main menu
	var current_rank = RATING_RANK.get(run_rating, 0)
	var saved_rank   = RATING_RANK.get(best_rating, -1)
	if current_rank > saved_rank:
		best_score  = run_score
		best_time   = run_time
		best_rating = run_rating
		save_best()
	elif current_rank == saved_rank:
		if run_score > best_score:
			best_score  = run_score
			best_time   = run_time
			best_rating = run_rating
			save_best()
		elif run_score == best_score and run_time < best_time:
			best_score  = run_score
			best_time   = run_time
			best_rating = run_rating
			save_best()

	# Insert into leaderboard
	_insert_record(run_score, run_time, run_rating)

func save_best():
	var config = ConfigFile.new()
	config.set_value("best", "score",  best_score)
	config.set_value("best", "time",   best_time)
	config.set_value("best", "rating", best_rating)
	config.save("user://best_run.cfg")

func load_best():
	var config = ConfigFile.new()
	if config.load("user://best_run.cfg") == OK:
		best_score  = config.get_value("best", "score",  0)
		best_time   = config.get_value("best", "time",   0.0)
		best_rating = config.get_value("best", "rating", "")

# ─── Leaderboard ──────────────────────────────────────────────────────────────

func _insert_record(run_score: int, run_time: float, run_rating: String):
	var new_record = {"score": run_score, "time": run_time, "rating": run_rating}
	leaderboard.append(new_record)

	# Sort: best first using _compare_records
	leaderboard.sort_custom(_compare_records)

	# Cap at MAX_RECORDS
	if leaderboard.size() > MAX_RECORDS:
		leaderboard.resize(MAX_RECORDS)

	# Remember which rank this run ended up at
	latest_record_index = -1
	for i in range(leaderboard.size()):
		var r = leaderboard[i]
		if r.get("score", -1) == run_score and abs(r.get("time", -1.0) - run_time) < 0.01 and r.get("rating", "") == run_rating:
			latest_record_index = i
			break

	save_leaderboard()

func get_top_records() -> Array:
	return leaderboard

func is_latest_record(index: int) -> bool:
	return index == latest_record_index

func save_leaderboard():
	var config = ConfigFile.new()
	config.set_value("leaderboard", "count", leaderboard.size())
	for i in range(leaderboard.size()):
		var r = leaderboard[i]
		config.set_value("leaderboard", "score_%d"  % i, r.get("score",  0))
		config.set_value("leaderboard", "time_%d"   % i, r.get("time",   0.0))
		config.set_value("leaderboard", "rating_%d" % i, r.get("rating", "D"))
	config.save("user://leaderboard.cfg")

func load_leaderboard():
	leaderboard.clear()
	var config = ConfigFile.new()
	if config.load("user://leaderboard.cfg") != OK:
		return
	var count = config.get_value("leaderboard", "count", 0)
	for i in range(count):
		leaderboard.append({
			"score":  config.get_value("leaderboard", "score_%d"  % i, 0),
			"time":   config.get_value("leaderboard", "time_%d"   % i, 0.0),
			"rating": config.get_value("leaderboard", "rating_%d" % i, "D"),
		})
		
func reset_run():
	score = 0
	level_time = 0.0
	timer_running = false
	game_started = false
	player_dead = false
	stages_completed = 0
	current_difficulty = "easy"
	refill_map_pool()
	
func load_settings_on_start():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var bgm = config.get_value("audio", "bgm", 100.0)
		var sfx = config.get_value("audio", "sfx", 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), linear_to_db(bgm / 100.0))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx / 100.0))

# ─── Progress (tutorial completion) ───────────────────────────────────────────

func save_progress():
	var config = ConfigFile.new()
	config.set_value("progress", "tutorial_completed", tutorial_completed)
	config.save("user://progress.cfg")

func load_progress():
	var config = ConfigFile.new()
	if config.load("user://progress.cfg") == OK:
		tutorial_completed = config.get_value("progress", "tutorial_completed", false)
	else:
		tutorial_completed = false

func mark_tutorial_completed():
	tutorial_completed = true
	save_progress()
