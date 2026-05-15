extends Node2D

func _ready():
	pass

func _on_back_button_pressed() -> void:
	TransitionLayer.play_full_transition("res://Scenes/main_menu.tscn")
