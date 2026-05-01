extends CharacterBody2D

const MOVE_SPEED = 80.0
const CHARGE_SPEED = 1200.0
const BULLET_SCENE = preload("res://Scenes/bullet.tscn")

var hp = 5
var player = null
var is_charging = false
var is_dead = false
var charge_direction = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var bullet_timer = $BulletTimer
@onready var ability_timer = $AbilityTimer
@onready var charge_indicator = get_parent().get_node("ChargeIndicator")
@onready var exit_door = get_parent().get_node("ExitDoor")

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	bullet_timer.wait_time = 4.0
	bullet_timer.timeout.connect(_shoot_bullets)
	bullet_timer.start()
	ability_timer.wait_time = 7.0
	ability_timer.timeout.connect(_start_charge_sequence)
	ability_timer.start()
	
	# Keep exit closed
	exit_door.monitoring = false
	exit_door.get_node("CollisionShape2D").disabled = true

func _physics_process(delta):
	if is_dead or is_charging or player == null:
		return
	
	# Slowly float toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * MOVE_SPEED
	move_and_slide()
	
	# Check collision with exposed spikes during charge
	for wall in get_tree().get_nodes_in_group("Wall"):
		if wall.is_exposed and global_position.distance_to(wall.global_position) < 40:
			if is_charging:
				take_damage()

func _shoot_bullets():
	if is_dead or is_charging:
		return
	
	var bullet_count = randi_range(5, 6)
	for i in range(bullet_count):
		var bullet = BULLET_SCENE.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		
		# Spread bullets in a cone toward player
		var base_dir = (player.global_position - global_position).normalized()
		var spread = deg_to_rad(randf_range(-25, 25))
		bullet.direction = base_dir.rotated(spread)

func _start_charge_sequence():
	if is_dead or is_charging:
		return
	
	# Show charge indicator line
	charge_direction = (player.global_position - global_position).normalized()
	charge_indicator.visible = true
	charge_indicator.points = [
		global_position,
		global_position + charge_direction * 800
	]
	
	# Delay before charging
	await get_tree().create_timer(1.5).timeout
	charge_indicator.visible = false
	_do_charge()

func _do_charge():
	is_charging = true
	velocity = charge_direction * CHARGE_SPEED
	
	# Check for spike collision during charge
	await get_tree().create_timer(1.0).timeout
	is_charging = false
	velocity = Vector2.ZERO

func take_damage():
	if is_dead:
		return
	hp -= 1
	GameManager.add_point()
	print("Boss HP: ", hp)
	
	if hp <= 0:
		die()

func die():
	is_dead = true
	bullet_timer.stop()
	ability_timer.stop()
	sprite.play("death")
	
	# Open exit door
	exit_door.monitoring = true
	exit_door.get_node("CollisionShape2D").disabled = false
	
	await sprite.animation_finished
	queue_free()
