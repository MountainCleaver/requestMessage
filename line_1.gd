extends LineEdit
class_name LineEdit1

@onready var click_sound = AudioStreamPlayer.new()
@onready var hover_sound = AudioStreamPlayer.new()
@onready var type_sound = AudioStreamPlayer.new()

func _ready() -> void:
	# CLICK sound (when LineEdit is focused)
	click_sound.stream = load("res://sound/select-button-ui-395763.mp3")
	click_sound.volume_db = -5
	click_sound.pitch_scale = 1.0
	click_sound.bus = "SFX"
	focus_entered.connect(func(): click_sound.play())
	add_child(click_sound)
	
	# HOVER sound (when mouse enters)
	hover_sound.stream = load("res://sound/button-hover-mp-sound.mp3")
	hover_sound.volume_db = -6
	hover_sound.pitch_scale = 1.1
	hover_sound.bus = "SFX"
	mouse_entered.connect(func(): hover_sound.play())
	add_child(hover_sound)
	
	# TYPING sound (when player types)
	type_sound.stream = load("res://sound/keyboard-typing-one-short-1-2925901.wav")
	type_sound.volume_db = -4
	type_sound.bus = "SFX"
	add_child(type_sound)
	
	text_changed.connect(_on_text_changed)

func _on_text_changed(new_text: String) -> void:
	if not type_sound.playing:
		type_sound.pitch_scale = randf_range(0.95, 1.05)
		type_sound.play()
