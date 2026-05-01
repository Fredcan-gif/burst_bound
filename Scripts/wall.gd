extends Area2D

var hp = 3
var is_exposed = false

@onready var shield_sprite = $ShieldSprite
@onready var spike_sprite = $SpikeSprite

func _ready():
	add_to_group("Wall")
	spike_sprite.visible = false

func take_damage():
	hp -= 1
	if hp <= 0:
		expose()

func expose():
	is_exposed = true
	shield_sprite.visible = false
	spike_sprite.visible = true
