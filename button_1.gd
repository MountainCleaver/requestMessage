extends Button
class_name Button1

@onready var click_sound = AudioStreamPlayer.new()
@onready var hover_sound = AudioStreamPlayer.new()

func _ready() -> void:
	# --- CLICK SOUND ---
	click_sound.stream = load("res://sound/select-button-ui-395763.mp3")
	click_sound.volume_db = -4
	click_sound.pitch_scale = 1.0
	click_sound.bus = "SFX"
	add_child(click_sound)

	# --- HOVER SOUND ---
	hover_sound.stream = load("res://sound/button-hover-mp-sound.mp3")
	hover_sound.volume_db = -6
	hover_sound.pitch_scale = 1.05
	hover_sound.bus = "SFX"
	add_child(hover_sound)

	# --- SIGNALS ---
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	if not hover_sound.playing:
		hover_sound.pitch_scale = randf_range(0.95, 1.05) # adds variation
		hover_sound.play()

func _on_pressed() -> void:
	click_sound.stop() # prevent overlap
	click_sound.pitch_scale = randf_range(0.95, 1.05)
	click_sound.play()
