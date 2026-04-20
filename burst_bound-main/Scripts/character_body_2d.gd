extends CharacterBody2D

# Movement Constants
const SPEED = 350.0
const JUMP_VELOCITY = -300.0
const DASH_SPEED = 600.0

# --- NEW: LOCK VARIABLE ---
var can_move = true 

# Dash Variables
var max_dashes = 5
var dashes_left = 5
var is_dashing = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $AnimatedSprite2D

func _physics_process(delta):
	# --- NEW: INPUT LOCK CHECK ---
	if not can_move:
		# Apply gravity so they don't float, but stop horizontal movement
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
			
		velocity.x = 0
		move_and_slide()
		update_animations(0) # Force idle animation
		return
	# --------------------------

	# 1. Add Gravity
	if not is_on_floor() and not is_dashing:
		velocity.y += gravity * delta
	elif is_on_floor():
		dashes_left = max_dashes

	# 2. Handle Jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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
		sprite.play("jump")
	else:
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
