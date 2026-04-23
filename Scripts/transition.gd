extends CanvasLayer
signal mid_way

func _ready():
	$TopBar.position.y = -216
	$BottomBar.position.y = 432
	$AnimationPlayer.stop()

func _process(_delta):
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	
	var is_main_menu = current_scene.scene_file_path == "res://Scenes/main_menu.tscn"
	var should_show = not is_main_menu and not GameManager.player_dead

	$Label.visible = should_show
	$TimerLabel.visible = should_show
	
	if should_show:
		$Label.text = "Score: " + str(GameManager.score)
		var total_seconds = GameManager.level_time
		var minutes = int(total_seconds) / 60
		var seconds = int(total_seconds) % 60
		var milliseconds = int(fmod(total_seconds, 1.0) * 100)
		$TimerLabel.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func play_full_transition(target_scene: String):
	var old_player = get_tree().get_first_node_in_group("Player")
	if old_player:
		old_player.can_move = false
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
		
		if new_player:
			new_player.can_move = true
