extends CanvasLayer

signal mid_way 

func _ready():
	# Move bars off-screen immediately when the game boots up
	$TopBar.position.y = -216
	$BottomBar.position.y = 432
	$AnimationPlayer.stop()

func _process(_delta):
	$Label.text = "Score: " + str(GameManager.score)

func play_full_transition(target_scene: String):
	# 1. Find the current player and freeze them
	var old_player = get_tree().get_first_node_in_group("Player")
	if old_player:
		old_player.can_move = false

	$AnimationPlayer.play("close_and_open")
	await mid_way 
	
	var error = get_tree().change_scene_to_file(target_scene)
	
	if error == OK:
		# 2. Wait a tiny bit for the new scene to actually instantiate the nodes
		await get_tree().process_frame 
		
		# 3. Find the NEW player in the new level and keep them frozen
		var new_player = get_tree().get_first_node_in_group("Player")
		if new_player:
			new_player.can_move = false
		
		# 4. Finish the animation
		$AnimationPlayer.play("close_and_open")
		$AnimationPlayer.seek(0.5, true)
		
		# 5. Wait for the animation to finish before unfreezing
		await $AnimationPlayer.animation_finished
		
		# 6. Unfreeze the player!
		if new_player:
			new_player.can_move = true
