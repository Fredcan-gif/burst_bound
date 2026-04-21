extends CharacterBody2D

# Movement Constants
const SPEED = 600
const JUMP_VELOCITY = -800.0
const DASH_SPEED = 1300.0

# Lock Variable
var can_move = true

# Dash Variables
var max_dashes = 5
var dashes_left = 5
var is_dashing = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dead = false
var fall_start_played = false

@onready var sprite = $AnimatedSprite2D

func _ready():
	# Start timer when player spawns into the level
	GameManager.start_level_timer()

func _draw():
	var pip_size = Vector2(4, 4)
	var pip_gap = 1
	var start_offset = Vector2(-10, -20)
	
	for i in range(max_dashes):
		var pip_pos = start_offset + Vector2(i * (pip_size.x + pip_gap), 0)
		if i < dashes_left:
			draw_rect(Rect2(pip_pos, pip_size), Color(1, 1, 1, 1))
		else:
			draw_rect(Rect2(pip_pos, pip_size), Color(0.3, 0.3, 0.3, 0.8))

func _physics_process(delta):
	if not can_move:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
		velocity.x = 0
		move_and_slide()
		update_animations(0)
		return

	# 1. Add Gravity
	if not is_on_floor() and not is_dashing:
		velocity.y += gravity * delta
	elif is_on_floor():
		if dashes_left < max_dashes:
			dashes_left = max_dashes
		fall_start_played = false

	# 2. Handle Jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		fall_start_played = false

	# 3. Handle Dash Input
	if Input.is_action_just_pressed("move_dash") and dashes_left > 0:
		start_dash()

	# 4. Standard Horizontal Movement
	var direction = Input.get_axis("move_left", "move_right")
	if not is_dashing:
		if direction:
			velocity.x = direction * SPEED
			sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animations(direction)
	queue_redraw()

func start_dash():
	var dash_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT

	dashes_left -= 1
	is_dashing = true
	velocity = dash_direction.normalized() * DASH_SPEED

	var angle = dash_direction.angle()
	if dash_direction.x < 0:
		sprite.flip_h = true
		sprite.rotation = angle + PI
	else:
		sprite.flip_h = false
		sprite.rotation = angle
		sprite.flip_v = false

	$DashTimer.start(0.2)

func update_animations(direction):
	if is_dead:
		return
	if not can_move:
		sprite.play("idle")
		sprite.rotation = 0
		return
	if is_dashing:
		sprite.play("dash")
		return

	sprite.rotation = 0
	sprite.flip_v = false

	if not is_on_floor():
		if velocity.y > 0:
			if not fall_start_played:
				if sprite.animation != "fall_start":
					sprite.play("fall_start")
				if not sprite.is_playing():
					fall_start_played = true
					sprite.play("fall_loop")
			else:
				sprite.play("fall_loop")
		else:
			sprite.play("jump")
			fall_start_played = false
	else:
		fall_start_played = false
		if direction != 0:
			sprite.play("run")
			sprite.flip_h = direction < 0
		else:
			sprite.play("idle")

func _on_dash_timer_timeout():
	is_dashing = false
	velocity = Vector2.ZERO
	sprite.rotation = 0
	sprite.flip_v = false

func die():
	if not can_move:
		return
	can_move = false
	is_dead = true
	velocity = Vector2.ZERO
	sprite.play("death")
	GameManager.stop_level_timer()
	if not sprite.animation_finished.is_connected(_on_death_animation_finished):
		sprite.animation_finished.connect(_on_death_animation_finished)

func _on_death_animation_finished():
	if sprite.animation == "death":
		await get_tree().create_timer(0.5).timeout
		# Load and show death screen
		var death_screen = load("res://Scenes/death_screen.tscn").instantiate()
		get_tree().root.add_child(death_screen)
		death_screen.show_results(GameManager.score, GameManager.level_time)
