extends CharacterBody2D
@export var speed = 250.0
@export var gravity = 980.0

var player = null
var chase_player = false

# Roam variables
var roam_direction = 1
var roam_timer = 0.0
var roam_duration = 0.0
var is_roaming = false

@onready var sprite = $AnimatedSprite2D
@onready var ledge_check = $LedgeCheck

func _ready():
	randomize()
	pick_roam_action()

func pick_roam_action():
	# Randomly decide to either roam or idle
	if randi() % 2 == 0:
		is_roaming = true
		roam_direction = [-1, 1].pick_random()
		roam_duration = randf_range(1.0, 3.0)
	else:
		is_roaming = false
		roam_duration = randf_range(0.5, 2.0)
	roam_timer = roam_duration

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	var direction = 0

	if chase_player and player:
		var diff_x = player.global_position.x - global_position.x
		if abs(diff_x) > 10.0:
			direction = sign(diff_x)
			ledge_check.position.x = direction * 6
			if is_on_floor() and not ledge_check.is_colliding():
				direction = 0
				velocity.x = 0
	else:
		# Roam logic
		roam_timer -= delta
		if roam_timer <= 0:
			pick_roam_action()

		if is_roaming:
			ledge_check.position.x = roam_direction * 6
			# Flip roam direction at ledges
			if is_on_floor() and not ledge_check.is_colliding():
				roam_direction *= -1
			direction = roam_direction

	if direction != 0:
		velocity.x = direction * speed * (0.4 if not chase_player else 1.0)
		sprite.flip_h = direction < 0
		sprite.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		sprite.play("idle")
	move_and_slide()

func _on_detection_area_body_entered(body):
	if body.has_method("die"):
		player = body
		chase_player = true

func _on_detection_area_body_exited(body):
	if body == player:
		player = null
		chase_player = false

func _on_hitbox_body_entered(body):
	if body.has_method("die"):
		body.die()
