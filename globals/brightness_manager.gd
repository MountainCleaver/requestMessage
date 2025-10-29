extends TextureRect

const MIN_BRIGHTNESS := 0.65
const MAX_BRIGHTNESS := 1.0

var brightness := 1.0 

func _ready():
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color(0,0,0,0)

	if get_parent() != get_tree().root:
		get_tree().root.add_child(self)

	set_brightness(Settings.settings.brightness)

	var callable := Callable(self, "_on_scene_changed")
	if not get_tree().is_connected("current_scene_changed", callable):
		get_tree().connect("current_scene_changed", callable)

func set_brightness(value: float) -> void:
	var normalized = clamp(value / 100.0, 0.0, 1.0)
	var brightness_value = MIN_BRIGHTNESS + (MAX_BRIGHTNESS - MIN_BRIGHTNESS) * normalized

	modulate = Color(1,1,1, 1.0 - brightness_value)

	print("Brightness set:", value, "-> overlay alpha:", modulate.a)

	Settings.settings.brightness = value
	Settings.save_settings()

func _on_scene_changed():
	if get_parent() == get_tree().root:
		get_tree().root.move_child(self, get_tree().root.get_child_count() - 1)
