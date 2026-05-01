extends Area2D

@onready var saw_fx = $SawFX

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("die"):
		body.die()
		saw_fx.play() 
