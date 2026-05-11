extends Node

@onready var player_a = $AudioStreamPlayerA
@onready var player_b = $AudioStreamPlayerB

var current_player: AudioStreamPlayer = null
var other_player: AudioStreamPlayer = null
var is_dying = false

const MUSIC = {
	"easy": [
		preload("res://Assets/Music/Easy/musinova-acid-bonus-liquid-breakbeat-jungle-drum-and-bass-loopable-version-354205.mp3"),
		preload("res://Assets/Music/Easy/aka4aerk-aerk-core-11-one-254475.mp3"),
	],
	"medium": [
		preload("res://Assets/Music/Medium/musinova-ultra-speed-liquid-jungle-breakbeat-drum-and-bass-loopable-edit-356522.mp3"),
		preload("res://Assets/Music/Medium/musinova-wandering-stars-liquid-jungle-drum-and-bass-loopable-version-356497.mp3"),
	],
	"hard": [
		preload("res://Assets/Music/Hard/musinova-cyber-breaks-liquid-jungle-breakbeat-drum-and-bass-loopable-edit-470306.mp3"),
		preload("res://Assets/Music/Hard/musinova-information-flow-liquid-jungle-breakbeat-drum-and-bass-loop-358433.mp3"),
	],
	"boss": [
		preload("res://Assets/Music/Boss/keyframe_audio-dust-up-133891.mp3"),
	],
}

var current_difficulty = "easy"
var remaining_tracks = []
var ramp_up_on_next = false

func _ready():
	current_player = player_a
	other_player = player_b
	player_a.finished.connect(_on_track_finished)
	player_b.finished.connect(_on_track_finished)

func play_for_difficulty(difficulty: String):
	if is_dying:
		return
	current_difficulty = difficulty
	remaining_tracks = MUSIC[difficulty].duplicate()
	remaining_tracks.shuffle()
	play_next_track()

func play_next_track():
	if remaining_tracks.is_empty():
		remaining_tracks = MUSIC[current_difficulty].duplicate()
		remaining_tracks.shuffle()
	var track = remaining_tracks.pop_back()
	current_player.stream = track
	current_player.pitch_scale = 1.0  # Always start at 1.0
	current_player.play()
	
	if ramp_up_on_next:
		ramp_up_on_next = false
		current_player.pitch_scale = 0.3  # Set low AFTER play()
		ramp_up_pitch()

func ramp_up_pitch():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(current_player, "pitch_scale", 1.0, 1.5)

func _on_track_finished():
	play_next_track()

func on_player_die():
	if is_dying:
		return
	is_dying = true
	slow_down_and_stop()

func slow_down_and_stop():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(current_player, "pitch_scale", 0.01, 2.0)
	await tween.finished
	current_player.stop()
	current_player.pitch_scale = 1.0

func reset():
	is_dying = false
	ramp_up_on_next = true
	current_player.pitch_scale = 1.0
	
func reset_to_menu():
	is_dying = false
	ramp_up_on_next = false
	if current_player.playing:
		current_player.stop()
	current_player.pitch_scale = 1.0

func reset_for_restart():
	is_dying = false
	ramp_up_on_next = true
	current_player.pitch_scale = 1.0
