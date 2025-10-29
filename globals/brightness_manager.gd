extends CanvasModulate

# ----------------------
# CONFIG
# ----------------------
const MIN_BRIGHTNESS := 0.5
const MAX_BRIGHTNESS := 1.0

var brightness := 1.0

# ----------------------
# READY
# ----------------------
func _ready():
	set_brightness(Settings.settings.brightness)
	print("BrightnessManager ready, initial brightness:", brightness)

# ----------------------
# SET BRIGHTNESS
# ----------------------
func set_brightness(value: float) -> void:
	var normalized = clamp(value / 100.0, 0.0, 1.0)
	brightness = normalized

	var brightness_value = MIN_BRIGHTNESS + (MAX_BRIGHTNESS - MIN_BRIGHTNESS) * normalized

	color = Color(brightness_value, brightness_value, brightness_value, 1)

	Settings.settings.brightness = value
	Settings.save_settings()

	print("Brightness set:", value, "-> color:", color)

func _on_scene_changed():
	if get_parent() != get_tree().root:
		get_tree().root.add_child(self)
		print("BrightnessManager reparented to root")
