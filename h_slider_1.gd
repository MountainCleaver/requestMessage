extends HSlider
class_name HSlider1

@onready var drag_sound = AudioStreamPlayer.new()

func _ready() -> void:
	# --- DRAG SOUND ---
	drag_sound.stream = load("res://sound/interface-button-154180.mp3")
	drag_sound.volume_db = -4
	drag_sound.pitch_scale = 1.0
	drag_sound.bus = "SFX"
	add_child(drag_sound)

	# Connect drag start
	drag_started.connect(_on_drag_started)

func _on_drag_started() -> void:
	drag_sound.stop()
	drag_sound.pitch_scale = randf_range(0.95, 1.05) # small pitch variation for realism
	drag_sound.play()
