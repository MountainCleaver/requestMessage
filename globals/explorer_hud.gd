extends CanvasLayer

# ===================
# NODES
# ===================
@onready var map_icon = $Map
@onready var full_map = $FullMapPanel
@onready var flashlight_button = $Flashlight

# ===================
# VARIABLES
# ===================
var is_open = false
var fade_duration := 0.2  # seconds

# ===================
# READY
# ===================
func _ready():
	flashlight_button.visible = false  # ensure hidden at start

	map_icon.pressed.connect(_toggle_map)
	full_map.modulate.a = 0
	full_map.visible = false

	# Connect to flashlight unlock signal
	FlashlightManager.connect("real_flashlight_unlocked_signal", Callable(self, "_on_flashlight_unlocked"))

	# Connect to scene changed signal
	FlashlightManager.connect("current_scene_changed", Callable(self, "_on_scene_changed"))

	# Initial visibility check
	_update_flashlight_visibility()

func _on_scene_changed(act: String, scene: String):
	_update_flashlight_visibility()

# ===================
# FLASHLIGHT SIGNAL
# ===================
func _on_flashlight_unlocked():
	if not flashlight_button.visible:
		flashlight_button.visible = true
		flashlight_button.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(flashlight_button, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		print("[ExplorerHUD] Flashlight button is now visible with fade-in.")

# ===================
# UPDATE FLASHLIGHT VISIBILITY
# ===================
func _update_flashlight_visibility():
	var act = FlashlightManager.data.get("current_act", "")
	var scene = FlashlightManager.data.get("current_scene", "")

	if act != "act_4":
		flashlight_button.visible = false
		return

	var scene_number = int(scene.replace("scene_", "0"))  # default 0 if empty

	if scene_number == 1:
		# Special case: only show if player unlocked via Lola Ising
		if FlashlightManager.real_flashlight_unlocked:
			flashlight_button.visible = true
			flashlight_button.modulate.a = 1.0
			print("[ExplorerHUD] Flashlight button enabled (Act 4 Scene 1).")
		else:
			flashlight_button.visible = false
	else:
		# Scenes >=2: show if cash given or unlocked
		if FlashlightManager.real_flashlight_unlocked or SaveManager.has_given_lola_ising_cash():
			flashlight_button.visible = true
			flashlight_button.modulate.a = 1.0
			print("[ExplorerHUD] Flashlight button enabled (Act 4 Scene >=2).")
		else:
			flashlight_button.visible = false

# ===================
# INPUT
# ===================
func _input(event):
	if event.is_action_pressed("map"):
		_toggle_map()

# ===================
# MAP TOGGLE
# ===================
func _toggle_map():
	if is_open:
		is_open = false
		await _fade_out()
	else:
		full_map.visible = true
		is_open = true
		await _fade_in()

# ===================
# FADE IN/OUT
# ===================
func _fade_in() -> void:
	full_map.modulate.a = 0
	var timer := 0.0
	while timer < fade_duration:
		timer += get_process_delta_time()
		full_map.modulate.a = clamp(timer / fade_duration, 0, 1)
		await get_tree().process_frame
	full_map.modulate.a = 1

func _fade_out() -> void:
	var timer := 0.0
	while timer < fade_duration:
		timer += get_process_delta_time()
		full_map.modulate.a = clamp(1 - (timer / fade_duration), 0, 1)
		await get_tree().process_frame
	full_map.modulate.a = 0
	full_map.visible = false
