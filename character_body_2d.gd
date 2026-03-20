extends CharacterBody2D

# Movement Constants
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 700.0
const SPRITE_OFFSET = 0 # Change to PI/2 if facing UP, -PI/2 if facing DOWN

# Dash Variables
var max_dashes = 5
var dashes_left = 5
var is_dashing = false

# Get gravity from project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Reference to your AnimatedSprite2D node
@onready var sprite = $AnimatedSprite2D

func _physics_process(delta):
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
			# Flip the sprite based on direction
			sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	update_animations(direction)

func start_dash():
	# 1. Get the direction
	var dash_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Fallback if no keys are pressed
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	
	dashes_left -= 1
	is_dashing = true
	velocity = dash_direction.normalized() * DASH_SPEED
	
	# 2. ROTATION LOGIC
	var angle = dash_direction.angle()
	# Normalize the angle so the sprite faces the dash direction correctly
	if dash_direction.x < 0:
		# Dashing leftward: flip sprite horizontally, adjust rotation
		sprite.flip_h = true
		sprite.rotation = angle + PI
	else:
		sprite.flip_h = false
		sprite.rotation = angle
		# No flip_v needed
		sprite.flip_v = false
			
	$DashTimer.start(0.2)

func update_animations(direction):
	if is_dashing:
		sprite.play("dash")
		return # Stops the rest of the function from overriding our rotation
		
	# RESET EVERYTHING when not dashing
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
	# Ensure rotation resets immediately
	sprite.rotation = 0
	sprite.flip_v = false
