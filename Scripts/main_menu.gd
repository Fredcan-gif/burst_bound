extends Node2D

@onready var best_rating_label = $BestRunContainer/RatingRow/BestRatingLabel
@onready var best_score_label = $BestRunContainer/ScoreRow/BestScoreLabel
@onready var best_time_label = $BestRunContainer/TimeRow/BestTimeLabel
@onready var description_label = $Menu/Button_manager/DescriptionLabel

const DESCRIPTIONS = {
	"start": "Enter the gauntlet. Survive as long as you can.",
	"tutorial": "Learn the basics before diving in.",
	"exit": "Quit the game."
}

func _ready():
	GameManager.reset_run()
	description_label.text = ""  # Empty by default
	
	# Connect hover signals for each button
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
		var time_string = "%02d:%02d.%02d" % [int(t) / 60, int(t) % 60, int(fmod(t, 1.0) * 100)]
		best_rating_label.text = GameManager.best_rating
		best_score_label.text = str(GameManager.best_score)
		best_time_label.text = time_string
		
	_load_leaderboard()

func _load_leaderboard():
	var records_list = $LeaderboardContainer/RecordsList
	if not records_list:
		return
	for child in records_list.get_children():
		child.queue_free()
	var records = await NakamaManager.fetch_leaderboard()
	for record in records:
		var label = Label.new()
		label.text = "#%d  %s  —  %d" % [int(record.rank), record.username, int(record.score)]
		label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		records_list.add_child(label)
				
func _on_quit_pressed():
	get_tree().quit()

func _on_start_pressed() -> void:
	GameManager.score = 0
	var first_map = GameManager.get_random_map()
	TransitionLayer.play_full_transition(first_map)
	
func _on_tutorial_pressed() -> void:
	TransitionLayer.play_full_transition("res://Scenes/tutorial_room_1.tscn")
