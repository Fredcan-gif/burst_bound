extends CanvasLayer
signal mid_way

func _ready():
	$AnimationPlayer.stop()

func _process(_delta):
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	
	var scene_path = current_scene.scene_file_path
	var is_main_menu = scene_path == "res://Scenes/main_menu.tscn"
	var is_tutorial = "tutorial" in scene_path.to_lower()
	var should_show = not is_main_menu and not is_tutorial and not GameManager.player_dead
	
	$HUDContainer/Label.visible = should_show
	$HUDContainer/TimerLabel.visible = should_show
	$HUDContainer/HUDBG.visible = should_show
	
	if should_show:
		$HUDContainer/Label.text = "Score: " + str(GameManager.score)
		var total_seconds = GameManager.level_time
		var minutes = int(total_seconds) / 60
		var seconds = int(total_seconds) % 60
		var milliseconds = int(fmod(total_seconds, 1.0) * 100)
		$HUDContainer/TimerLabel.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func play_full_transition(target_scene: String):
	var old_player = get_tree().get_first_node_in_group("Player")
	if old_player:
		old_player.can_move = false
		
	if has_node("TransitionFX"):
		$TransitionFX.pitch_scale = 1.2
		$TransitionFX.play()
		
	$AnimationPlayer.play("close_and_open")
	await mid_way 
	
	var error = get_tree().change_scene_to_file(target_scene)
	
	if error == OK:
		await get_tree().process_frame 
		
		var new_player = get_tree().get_first_node_in_group("Player")
		if new_player:
			new_player.can_move = false
		
		$AnimationPlayer.play("close_and_open")
		$AnimationPlayer.seek(0.5, true)
		
		await $AnimationPlayer.animation_finished
		
		if new_player and not Dialogue.is_showing:
			new_player.can_move = true
			
func play_full_transition_in_place(spawn_pos: Vector2, player):
	player.can_move = false
	
	if has_node("TransitionFX"):
		$TransitionFX.pitch_scale = 1.2
		$TransitionFX.play()
		
	if has_node("AlarmFX"):
		$AlarmFX.pitch_scale = 1.1
		$AlarmFX.play(1.0)
		
	$AnimationPlayer.play("close_and_open")
	await mid_way
	
	player.global_position = spawn_pos
	player.velocity = Vector2.ZERO
	
	$AnimationPlayer.play("close_and_open")
	$AnimationPlayer.seek(0.5, true)
	
	await $AnimationPlayer.animation_finished
	
	if not Dialogue.is_showing:
		player.can_move = true
