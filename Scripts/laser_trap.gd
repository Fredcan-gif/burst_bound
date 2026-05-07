extends Node2D

@export var laser_on_duration = 3.0   # How long laser stays active
@export var laser_off_duration = 2.0  # How long laser stays off
@export var start_delay = 0.0         # Offset so two lasers dont sync up

@onready var sprite = $AnimatedSprite2D
@onready var laser_hitbox = $LaserHitbox

func _ready():
	laser_hitbox.monitoring = false
	laser_hitbox.monitorable = false
	laser_hitbox.body_entered.connect(_on_laser_hit)
	sprite.animation_finished.connect(_on_animation_finished)
	
	# Wait for start delay before beginning cycle
	await get_tree().create_timer(start_delay).timeout
	start_activate()

func start_activate():
	sprite.play("activate")

func start_deactivate():
	laser_hitbox.set_deferred("monitoring", false)
	laser_hitbox.set_deferred("monitorable", false)
	sprite.play("deactivate")

func _on_animation_finished():
	match sprite.animation:
		"activate":
			laser_hitbox.monitoring = true
			laser_hitbox.monitorable = true
			sprite.play("idle")
			await get_tree().create_timer(laser_on_duration).timeout
			start_deactivate()
		"deactivate":
			await get_tree().create_timer(laser_off_duration).timeout
			start_activate()

func _on_laser_hit(body):
	if body.is_in_group("Player") and body.has_method("die"):
		body.die()
