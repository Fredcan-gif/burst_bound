extends AudioStreamPlayer

func _ready() -> void:
	play()

func change_music(new_stream: AudioStream) -> void:
	if stream == new_stream:
		return
	stream = new_stream
	play()
