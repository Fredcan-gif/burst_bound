extends Node2D

func _ready():
	GameManager.is_tutorial = false
	MusicManager.play_for_difficulty("boss")
