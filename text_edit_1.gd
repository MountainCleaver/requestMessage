extends TextEdit
class_name TextEdit1

@onready var click_sound = AudioStreamPlayer.new()
@onready var type_sound = AudioStreamPlayer.new()

func _ready() -> void:
	# --- CLICK SOUND (when focused) ---
	click_sound.stream = load("res://sound/select-button-ui-395763.mp3")
	click_sound.volume_db = -5
	click_sound.pitch_scale = 1.0
	click_sound.bus = "SFX"
	add_child(click_sound)

	# --- TYPING SOUND ---
	type_sound.stream = load("res://sound/keyboard-typing-one-short-1-2925901.wav")
	type_sound.volume_db = -4
	type_sound.pitch_scale = 1.0
	type_sound.bus = "SFX"
	add_child(type_sound)

	# --- CONNECT SIGNALS ---
	focus_entered.connect(_on_focus_entered)
	text_changed.connect(_on_text_changed)

func _on_focus_entered() -> void:
	click_sound.stop()
	click_sound.pitch_scale = randf_range(0.95, 1.05)
	click_sound.play()

func _on_text_changed() -> void:
	# Play typing sound only if not already playing
	if not type_sound.playing:
		type_sound.pitch_scale = randf_range(0.95, 1.05)
		type_sound.play()
