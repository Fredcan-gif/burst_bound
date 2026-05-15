extends Control

signal moved(direction: Vector2)
signal released()

@export var radius: float = 60.0
@export var deadzone: float = 10.0
@export var follow_finger: bool = true

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Knob

var _touch_index: int = -1
var _base_origin: Vector2
var _direction: Vector2 = Vector2.ZERO
var _active_actions: Array[String] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block any UI clicks
	_base_origin = base.global_position + base.size / 2.0
	knob.global_position = _base_origin - knob.size / 2.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1 and _is_inside(event.position):
				_touch_index = event.index
				if follow_finger:
					_base_origin = event.position
					base.global_position = _base_origin - base.size / 2.0
				_update(event.position)
		elif event.index == _touch_index:
			_reset()

	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update(event.position)


func _update(touch_pos: Vector2) -> void:
	var offset := touch_pos - _base_origin
	var clamped := offset.limit_length(radius)
	knob.global_position = _base_origin + clamped - knob.size / 2.0

	if offset.length() > deadzone:
		_direction = clamped / radius
	else:
		_direction = Vector2.ZERO

	_sync_actions()
	moved.emit(_direction)


func _sync_actions() -> void:
	for action in _active_actions:
		Input.action_release(action)
	_active_actions.clear()

	if _direction.x < -0.1:
		Input.action_press("move_left", abs(_direction.x))
		_active_actions.append("move_left")
	elif _direction.x > 0.1:
		Input.action_press("move_right", abs(_direction.x))
		_active_actions.append("move_right")

	if _direction.y < -0.1:
		Input.action_press("move_up", abs(_direction.y))
		_active_actions.append("move_up")
	elif _direction.y > 0.1:
		Input.action_press("move_down", abs(_direction.y))
		_active_actions.append("move_down")


func _reset() -> void:
	_touch_index = -1
	_direction = Vector2.ZERO
	if not follow_finger:
		_base_origin = base.global_position + base.size / 2.0
	knob.global_position = _base_origin - knob.size / 2.0
	for action in _active_actions:
		Input.action_release(action)
	_active_actions.clear()
	released.emit()


func _is_inside(pos: Vector2) -> bool:
	return (pos - _base_origin).length() <= radius * 1.5


func get_vector() -> Vector2:
	return _direction
