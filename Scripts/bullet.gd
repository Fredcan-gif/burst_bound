extends Area2D

var direction = Vector2.ZERO
const SPEED = 400.0

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * SPEED * delta

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.die()
	if body.is_in_group("Wall"):
		# Damage the wall
		body.take_damage()
	queue_free()
