extends Node2D

@onready var best_rating_label = $BestRunContainer/BestRatingLabel
@onready var best_score_label = $BestRunContainer/BestScoreLabel
@onready var best_time_label = $BestRunContainer/BestTimeLabel

func _ready():
	GameManager.reset_run()
	
	if GameManager.best_rating == "":
		best_rating_label.text = "Best Rating: —"
		best_score_label.text = "Best Score: —"
		best_time_label.text = "Best Time: —"
	else:
		var t = GameManager.best_time
		var time_string = "%02d:%02d.%02d" % [int(t) / 60, int(t) % 60, int(fmod(t, 1.0) * 100)]
		best_rating_label.text = "Best Rating: " + GameManager.best_rating
		best_score_label.text = "Best Score: " + str(GameManager.best_score)
		best_time_label.text = "Best Time: " + time_string

func _on_quit_pressed():
	get_tree().quit()

func _on_start_pressed() -> void:
	GameManager.score = 0
	var first_map = GameManager.get_random_map()
	TransitionLayer.play_full_transition(first_map)
