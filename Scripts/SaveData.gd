extends Node

# ─────────────────────────────────────────────
#  SaveData.gd  —  AutoLoad singleton
#  Add to AutoLoad BEFORE Leaderboard.gd
# ─────────────────────────────────────────────

const SAVE_PATH := "user://save.cfg"

var player_name    : String = ""
var best_score     : int    = 0
var best_rating    : String = "-"
var best_time_secs : int    = 0


func _ready() -> void:
	load_data()


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "name",      player_name)
	cfg.set_value("best",   "score",     best_score)
	cfg.set_value("best",   "rating",    best_rating)
	cfg.set_value("best",   "time_secs", best_time_secs)
	cfg.save(SAVE_PATH)


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	player_name    = cfg.get_value("player", "name",      "")
	best_score     = cfg.get_value("best",   "score",     0)
	best_rating    = cfg.get_value("best",   "rating",    "-")
	best_time_secs = cfg.get_value("best",   "time_secs", 0)


# Returns true if this run is a new personal best.
func try_save_run(score: int, rating: String, time_secs: int) -> bool:
	var is_best := score > best_score
	if is_best:
		best_score     = score
		best_rating    = rating
		best_time_secs = time_secs
		save_data()
	return is_best


func set_player_name(name: String) -> void:
	player_name = name.strip_edges().left(20)
	save_data()
