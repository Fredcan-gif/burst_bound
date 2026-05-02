extends StaticBody2D

var hp = 3
var is_exposed = false

@onready var shield_sprite = $ShieldSprite
@onready var spike_sprite = $SpikeSprite
@onready var boss_detector = $BossDetector
@onready var shield_collision = $ShieldCollision
@onready var spike_collision = $SpikeCollision

func _ready():
	add_to_group("Wall")
	spike_sprite.visible = false
	spike_collision.disabled = true  # Start with spike collision off
	boss_detector.body_entered.connect(_on_boss_hit)
	
func _on_boss_hit(body):
	if body.is_in_group("Boss") and body.is_charging:
		take_damage()
		flash()

func flash():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(10, 10, 10, 1), 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.05)
	tween.tween_property(self, "modulate", Color(10, 10, 10, 1), 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.05)

func take_damage():
	if is_exposed:
		return
	hp -= 1
	print("Wall HP: ", hp)
	if hp <= 0:
		expose()

func expose():
	is_exposed = true
	shield_sprite.visible = false
	spike_sprite.visible = true
	shield_collision.set_deferred("disabled", true)
	spike_collision.set_deferred("disabled", false)
