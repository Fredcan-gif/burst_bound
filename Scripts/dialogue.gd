extends CanvasLayer

signal dialogue_finished

@onready var dialogue_box = $DialogueBox
@onready var name_label = $DialogueBox/NameLabel
@onready var dialogue_label = $DialogueBox/DialogueLabel
@onready var continue_label = $DialogueBox/ContinueLabel

var dialogue_queue = []
var is_showing = false
var is_typing = false
var full_text = ""
var player = null
var just_closed = false

func _ready():
	dialogue_box.visible = false

func start_dialogue(lines: Array, delay: float = 0.5):
	player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = false
	
	await get_tree().create_timer(delay).timeout
	dialogue_queue = lines.duplicate()
	is_showing = true
	dialogue_box.visible = true
	show_next_line()

func end_dialogue():
	is_showing = false
	dialogue_box.visible = false
	if player and is_instance_valid(player):
		player.can_move = true
	player = null
	just_closed = true
	emit_signal("dialogue_finished")

func _process(_delta):
	if just_closed:
		just_closed = false

func _input(event):
	if not is_showing:
		return
	
	var tapped = event is InputEventScreenTouch and event.pressed
	var clicked = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	
	if tapped or clicked:
		if is_typing:
			is_typing = false
		else:
			show_next_line()
			
func show_next_line():
	if dialogue_queue.is_empty():
		end_dialogue()
		return
	var line = dialogue_queue.pop_front()
	name_label.text = line.get("name", "")
	full_text = line.get("text", "")
	dialogue_label.text = ""
	continue_label.visible = false
	type_text()

func type_text():
	is_typing = true
	for i in range(full_text.length()):
		if not is_typing:
			break
		dialogue_label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(0.03).timeout
	dialogue_label.text = full_text
	is_typing = false
	continue_label.visible = true
