extends Node

var score = 0
var stages_completed = 0
var current_difficulty = "easy"
var boss_count = 0

var easy_maps = [
	"res://Scenes/level_easy_1.tscn",
	"res://Scenes/level_easy_2.tscn",
	"res://Scenes/level_easy_3.tscn",
]

var medium_maps = [
	"res://Scenes/level_medium_1.tscn",
	"res://Scenes/level_medium_2.tscn",
	"res://Scenes/level_medium_3.tscn",
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

# Best run
var best_score = 0
var best_time = 0.0
var best_rating = ""

func _ready():
	refill_map_pool()
	load_best()

func _process(delta):
	if timer_running:
		level_time += delta

func get_current_pool() -> Array:
	match current_difficulty:
		"easy": return easy_maps
		"medium": return medium_maps
		"hard": return hard_maps
	return easy_maps

func refill_map_pool():
	remaining_maps = get_current_pool().duplicate()
	remaining_maps.shuffle()

func get_next_map() -> String:
	# Every 10 stages trigger boss
	if stages_completed > 0 and stages_completed % 10 == 0:
		return "res://Scenes/boss_stage_1.tscn"
	
	if remaining_maps.is_empty():
		refill_map_pool()
	
	return remaining_maps.pop_back()

func complete_stage():
	stages_completed += 1
	print("Stages completed: ", stages_completed)
	
	# After boss (every 10 stages) advance difficulty
	if stages_completed % 10 == 0:
		advance_difficulty()

func advance_difficulty():
	match current_difficulty:
		"easy":
			current_difficulty = "medium"
			print("Difficulty: Medium")
		"medium":
			current_difficulty = "hard"
			print("Difficulty: Hard")
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

func try_save_best(run_score: int, run_time: float, run_rating: String):
	if is_tutorial:
		return
	var rating_rank = {"D": 0, "C": 1, "B": 2, "A": 3, "A+": 4, "S": 5}
	var current_rank = rating_rank.get(run_rating, 0)
	var saved_rank = rating_rank.get(best_rating, -1)
	if current_rank > saved_rank:
		best_score = run_score
		best_time = run_time
		best_rating = run_rating
		save_best()
	elif current_rank == saved_rank:
		if run_score > best_score:
			best_score = run_score
			best_time = run_time
			best_rating = run_rating
			save_best()
		elif run_score == best_score and run_time < best_time:
			best_score = run_score
			best_time = run_time
			best_rating = run_rating
			save_best()

func save_best():
	var config = ConfigFile.new()
	config.set_value("best", "score", best_score)
	config.set_value("best", "time", best_time)
	config.set_value("best", "rating", best_rating)
	config.save("user://best_run.cfg")

func load_best():
	var config = ConfigFile.new()
	if config.load("user://best_run.cfg") == OK:
		best_score = config.get_value("best", "score", 0)
		best_time = config.get_value("best", "time", 0.0)
		best_rating = config.get_value("best", "rating", "")

func reset_run():
	score = 0
	level_time = 0.0
	timer_running = false
	game_started = false
	player_dead = false
	stages_completed = 0
	current_difficulty = "easy"
	refill_map_pool()
