extends Node

var score = 0
var maps = [
	"res://Scenes/level_1.tscn",
	"res://Scenes/level_2.tscn",
	"res://Scenes/level_3.tscn",
]
var remaining_maps = []

# Timer
var level_time = 0.0
var timer_running = false
var game_started = false
var player_dead = false

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

func start_level_timer():
	if game_started:
		return
	game_started = true
	level_time = 0.0
	timer_running = true

func stop_level_timer():
	timer_running = false
	game_started = false

func refill_map_pool():
	remaining_maps = maps.duplicate()
	remaining_maps.shuffle()

func get_random_map():
	if remaining_maps.size() == 0:
		refill_map_pool()
	var next_map = remaining_maps.pop_back()
	return next_map

func add_point():
	score += 1
	print("Current Score: ", score)

func try_save_best(run_score: int, run_time: float, run_rating: String):
	var rating_rank = {"D": 0, "C": 1, "B": 2, "A": 3, "A+": 4, "S": 5}
	var current_rank = rating_rank.get(run_rating, 0)
	var saved_rank = rating_rank.get(best_rating, -1)
	
	if current_rank > saved_rank:
		# Better rating always wins
		best_score = run_score
		best_time = run_time
		best_rating = run_rating
		save_best()
	elif current_rank == saved_rank:
		# Same rating — check score first
		if run_score > best_score:
			best_score = run_score
			best_time = run_time
			best_rating = run_rating
			save_best()
		elif run_score == best_score and run_time < best_time:
			# Same score — shorter time wins
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
	refill_map_pool()
