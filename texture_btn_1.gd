extends TextureButton
class_name TextureButton1

@onready var click_sound = AudioStreamPlayer.new()

func _ready() -> void:
	# --- CLICK SOUND ---
	click_sound.stream = load("res://sound/select-button-ui-395763.mp3")
	click_sound.volume_db = -4
	click_sound.pitch_scale = 1.0
	click_sound.bus = "SFX"
	add_child(click_sound)

	# --- CONNECT SIGNAL ---
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	click_sound.stop()  # prevent overlap on fast clicks
	click_sound.pitch_scale = randf_range(0.95, 1.05)
	click_sound.play()
