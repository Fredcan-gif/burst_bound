extends Node2D

@onready var bgm_slider = $Background/VBoxContainer/BGMRow/BGMSlider
@onready var sfx_slider = $Background/VBoxContainer/SFXRow/SFXSlider
@onready var bgm_value_label = $Background/VBoxContainer/BGMRow/BGMValueLabel
@onready var sfx_value_label = $Background/VBoxContainer/SFXRow/SFXValueLabel
@onready var confirm_popup = $Background/ConfirmPopup
@onready var confirm_yes = $Background/ConfirmPopup/ConfirmYes
@onready var confirm_no = $Background/ConfirmPopup/ConfirmNo

func _ready():
	confirm_popup.visible = false
	
	# Set slider ranges
	bgm_slider.min_value = 0.0
	bgm_slider.max_value = 100.0
	bgm_slider.step = 1.0
	
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 100.0
	sfx_slider.step = 1.0
	
	# Load saved settings
	load_settings()
	
	# Connect signals
	bgm_slider.value_changed.connect(_on_bgm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	confirm_yes.pressed.connect(_on_confirm_reset)
	confirm_no.pressed.connect(func(): confirm_popup.visible = false)

func _on_bgm_changed(value: float):
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("BGM"),
		linear_to_db(value / 100.0)
	)
	bgm_value_label.text = str(int(value))
	save_settings()

func _on_sfx_changed(value: float):
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value / 100.0)
	)
	sfx_value_label.text = str(int(value))
	save_settings()

func _on_confirm_reset():
	confirm_popup.visible = false
	
	# Delete saved files
	DirAccess.remove_absolute("user://best_run.cfg")
	DirAccess.remove_absolute("user://leaderboard.cfg")
	DirAccess.remove_absolute("user://settings.cfg")
	DirAccess.remove_absolute("user://progress.cfg")
	
	# Reset GameManager data
	GameManager.best_score = 0
	GameManager.best_time = 0.0
	GameManager.best_rating = ""
	GameManager.leaderboard.clear()
	GameManager.latest_record_index = -1
	GameManager.tutorial_completed = false
	
	# Reset sliders to default
	bgm_slider.value = 100.0
	sfx_slider.value = 100.0
	
	# Reset audio buses to full volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), 0.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), 0.0)

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "bgm", bgm_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		bgm_slider.value = config.get_value("audio", "bgm", 100.0)
		sfx_slider.value = config.get_value("audio", "sfx", 100.0)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("BGM"),
			linear_to_db(bgm_slider.value / 100.0)
		)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("SFX"),
			linear_to_db(sfx_slider.value / 100.0)
		)
	else:
		# No file — read current bus volume and set slider to match
		var bgm_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM"))
		var sfx_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
		bgm_slider.value = db_to_linear(bgm_db) * 100.0
		sfx_slider.value = db_to_linear(sfx_db) * 100.0
	
	bgm_value_label.text = str(int(bgm_slider.value))
	sfx_value_label.text = str(int(sfx_slider.value))

func _on_back_button_pressed() -> void:
	if has_meta("is_popup") and get_meta("is_popup"):
		queue_free()
	else:
		TransitionLayer.play_full_transition("res://Scenes/main_menu.tscn")

func _on_reset_pressed() -> void:
	confirm_popup.visible = true
