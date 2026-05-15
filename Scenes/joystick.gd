extends Control

var touch_index := -1
var start_pos := Vector2.ZERO
var threshold := 20.0

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x / 2:
			touch_index = event.index
			start_pos = event.position
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			start_pos = Vector2.ZERO
			_release_all()

	if event is InputEventScreenDrag and event.index == touch_index:
		var offset = event.position - start_pos
		_release_all()
		if offset.x > threshold:
			Input.action_press("move_right")
		elif offset.x < -threshold:
			Input.action_press("move_left")
		if offset.y > threshold:
			Input.action_press("move_down")
		elif offset.y < -threshold:
			Input.action_press("move_up")

func _release_all():
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("move_up")
	Input.action_release("move_down")
