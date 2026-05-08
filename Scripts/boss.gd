extends CharacterBody2D

const MOVE_SPEED = 300.0
const CHARGE_SPEED = 1800.0

var hp = 5
var max_hp = 5
var player = null
var is_charging = false
var is_dead = false
var charge_direction = Vector2.ZERO
var ability_timer = 0.0
const ABILITY_INTERVAL = 1.5  # Shorter cooldown
const CHARGE_WINDUP = 1  # ADD THIS
const MAX_CHARGE_DISTANCE = 1200.0  # ADD THIS

@onready var sprite = $AnimatedSprite2D
@onready var charge_indicator = get_parent().get_node("ChargeIndicator")
@onready var exit_door = get_parent().get_node("ExitDoor")
@onready var hp_bar = get_parent().get_node("CanvasLayer/BossHPBar")
@onready var hit_area = $HitArea
@onready var camera = get_parent().get_node("Camera2D")

@onready var alert_sfx = $AlertSFX
@onready var hurt_sfx = $HurtSFX
@onready var dead_sfx = $DeadSFX
@onready var charge_sfx = $ChargeSFX
@onready var hit_sfx = $HitSFX

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	charge_indicator.visible = false
	exit_door.set_deferred("monitoring", false)
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hit_area.body_entered.connect(_on_body_entered)

func screen_shake():
	var shake_duration = 0.3
	var shake_strength = 8.0
	var elapsed = 0.0
	
	while elapsed < shake_duration:
		camera.offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	
	camera.offset = Vector2.ZERO

func _on_body_entered(body):
	if body.is_in_group("Player") and body.has_method("die"):
		body.die()

func _physics_process(delta):
	if is_dead or player == null:
		return
	
	if not is_charging:
		ability_timer += delta
		
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * MOVE_SPEED
		sprite.flip_h = direction.x < 0
		
		move_and_slide()
		
		if ability_timer >= ABILITY_INTERVAL:
			ability_timer = 0.0
			start_charge_sequence()

func start_charge_sequence():
	if is_dead or is_charging:
		return
	is_charging = true
	velocity = Vector2.ZERO
	
	charge_direction = (player.global_position - global_position).normalized()
	sprite.flip_h = charge_direction.x < 0
	
	charge_indicator.global_position = Vector2.ZERO
	charge_indicator.points = [
		global_position,
		global_position + charge_direction * 1000
	]
	charge_indicator.visible = true
	alert_sfx.play(0.5)
	
	await get_tree().create_timer(CHARGE_WINDUP).timeout
	charge_indicator.visible = false
	alert_sfx.stop()
	
	await do_charge()
	is_charging = false

func do_charge():
	var charge_distance = 0.0
	charge_sfx.play()
	
	while charge_distance < MAX_CHARGE_DISTANCE and not is_dead:
		var move = charge_direction * CHARGE_SPEED * get_physics_process_delta_time()
		velocity = charge_direction * CHARGE_SPEED
		move_and_slide()
		charge_distance += move.length()
		
		if get_slide_collision_count() > 0:
			velocity = Vector2.ZERO
			charge_sfx.stop()
			hit_sfx.play()
			screen_shake()
			
			for wall in get_tree().get_nodes_in_group("Wall"):
				if wall.is_exposed:
					if global_position.distance_to(wall.global_position) < 200:
						hurt_sfx.play()  # ADD
						take_damage()
						wall.flash()
			
			var bounce_tween = create_tween()
			bounce_tween.set_ease(Tween.EASE_OUT)
			bounce_tween.set_trans(Tween.TRANS_QUAD)
			bounce_tween.tween_property(self, "global_position", global_position + (-charge_direction * 80), 0.2)
			await bounce_tween.finished
			return
		
		# Spike check during movement
		for wall in get_tree().get_nodes_in_group("Wall"):
			if wall.is_exposed:
				if global_position.distance_to(wall.global_position) < 200:
					charge_sfx.stop()
					hit_sfx.play()
					screen_shake()
					hurt_sfx.play()
					take_damage()
					wall.flash()
					return
		
		await get_tree().process_frame
	
	charge_sfx.stop()
	velocity = Vector2.ZERO

func take_damage():
	if is_dead:
		return
	hp -= 1
	hurt_sfx.play()  # Play when hitting spike
	hp_bar.value = hp
	GameManager.add_point()
	print("Boss HP: ", hp)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0, 0, 1), 0.1)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)
	
	if hp <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	sprite.play("death")
	dead_sfx.play()
	hp_bar.visible = false
	collision_layer = 0
	collision_mask = 0 
	hit_area.monitoring = false
	hit_area.monitorable = false
	MusicManager.play_for_difficulty(GameManager.current_difficulty)
	exit_door.set_deferred("monitoring", true)
	exit_door.set_deferred("monitorable", true)
	
	await sprite.animation_finished
	sprite.visible = false
	await dead_sfx.finished
	queue_free()
