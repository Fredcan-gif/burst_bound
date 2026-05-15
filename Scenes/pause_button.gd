extends TouchScreenButton

func _ready():
	pressed.connect(func():
		var event = InputEventAction.new()
		event.action = "ui_cancel"
		event.pressed = true
		Input.parse_input_event(event)
	)
