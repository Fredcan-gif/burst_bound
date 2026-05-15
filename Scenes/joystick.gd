extends Control

signal moved(direction: Vector2)
signal released()

@export var radius: float = 60.0
@export var deadzone: float = 10.0
@export var follow_finger: bool = true

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Knob

var _touch_index: int = -1
var _direction: Vector2 = Vector2.ZERO
var _active_actions: Array[String] = []

# --- Position Variables ---
var _base_origin: Vector2        # The CURRENT center of the joystick
var _home_base_pos: Vector2     # The ORIGINAL center where it sits at start


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Capture the original center point (Home)
	_home_base_pos = base.global_position + (base.size / 2.0)
	_base_origin = _home_base_pos
	_reset_ui()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# Start if we touch anywhere inside the Control's bounds 
			# or a specific detection radius
			if _touch_index == -1 and _is_inside(event.position):
				_touch_index = event.index
				
				if follow_finger:
					# Warp the base to where the finger touched
					_base_origin = event.position
					base.global_position = _base_origin - (base.size / 2.0)
				
				_update(event.position)
				
		elif event.index == _touch_index:
			_reset()

	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update(event.position)


func _update(touch_pos: Vector2) -> void:
	var offset := touch_pos - _base_origin
	var clamped := offset.limit_length(radius)
	knob.global_position = _base_origin + clamped - (knob.size / 2.0)

	if offset.length() > deadzone:
		_direction = clamped / radius
	else:
		_direction = Vector2.ZERO

	_sync_actions()
	moved.emit(_direction)


func _sync_actions() -> void:
	# Release previous frame's actions
	for action in _active_actions:
		Input.action_release(action)
	_active_actions.clear()

	# Horizontal
	if _direction.x < -0.1:
		Input.action_press("move_left", abs(_direction.x))
		_active_actions.append("move_left")
	elif _direction.x > 0.1:
		Input.action_press("move_right", abs(_direction.x))
		_active_actions.append("move_right")

	# Vertical
	if _direction.y < -0.1:
		Input.action_press("move_up", abs(_direction.y))
		_active_actions.append("move_up")
	elif _direction.y > 0.1:
		Input.action_press("move_down", abs(_direction.y))
		_active_actions.append("move_down")


func _reset() -> void:
	_touch_index = -1
	_direction = Vector2.ZERO
	
	# SNAP BACK TO HOME
	_base_origin = _home_base_pos
	_reset_ui()
	
	# Clean up input
	for action in _active_actions:
		Input.action_release(action)
	_active_actions.clear()
	released.emit()


func _reset_ui() -> void:
	# Move the visual base and knob back to the home origin
	base.global_position = _base_origin - (base.size / 2.0)
	knob.global_position = _base_origin - (knob.size / 2.0)


func _is_inside(pos: Vector2) -> bool:
	# If follow_finger is on, we check the home origin or a larger zone
	# Use the global rect of the Control node for easier detection
	return get_global_rect().has_point(pos)


func get_vector() -> Vector2:
	return _direction
