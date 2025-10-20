extends Node
# Flashlight Manager (autoload)
# ===================

# JSON file path
var save_path := "user://flashlight.json"

# Stored data
var data := {
	"real_flashlight_enabled": false,
	"phone_flashlight_enabled": false,
	"current_act": "",
	"current_scene": "",
	"real_flashlight_unlocked": false
}

# Node references
var player_real_flashlight: PointLight2D
var player_phone_flashlight: PointLight2D
var player_node: Node = null

signal phone_flashlight_enabled_signal

# Used to prevent repeating console spam
var _last_debug_message := ""

# ===================
# PROPERTIES
# ===================
var real_flashlight_enabled: bool:
	get: return data.get("real_flashlight_enabled", false)
	set(value):
		data["real_flashlight_enabled"] = value
		_update_lights()
		_save_json()

var phone_flashlight_enabled: bool:
	get: return data.get("phone_flashlight_enabled", false)
	set(value):
		data["phone_flashlight_enabled"] = value
		_update_lights()
		_save_json()

var real_flashlight_unlocked: bool:
	get: return data.get("real_flashlight_unlocked", false)
	set(value):
		data["real_flashlight_unlocked"] = value
		_save_json()

var flashlight_enabled: bool:
	get: return real_flashlight_enabled or phone_flashlight_enabled

# ===================
# INITIALIZATION
# ===================
func init(real_flash: PointLight2D, phone_flash: PointLight2D) -> void:
	player_real_flashlight = real_flash
	player_phone_flashlight = phone_flash
	player_node = real_flash.get_parent()  # Get reference to player (Danilo)
	
	# Load saved flashlight data
	_load_json()

	var act = data.get("current_act", "")
	var scene = data.get("current_scene", "")

	# Disable both flashlights completely for early acts
	if act in ["act_1", "act_2", "act_3"]:
		data["real_flashlight_enabled"] = false
		data["phone_flashlight_enabled"] = false

	elif act == "act_4" and scene == "scene_1":
		if not data.get("phone_flashlight_enabled", false):
			data["phone_flashlight_enabled"] = false
		else:
			_print_once("[FlashlightManager] Phone flashlight already unlocked — keeping ON.")

	elif act == "act_4":
		var scene_number = int(scene.replace("scene_", ""))
		# Re-enable flashlight after giving cash to Lola Ising
		if scene_number >= 2:
			if SaveManager.has_given_lola_ising_cash():
				data["real_flashlight_enabled"] = true
				data["real_flashlight_unlocked"] = true
				_print_once("[FlashlightManager] Real flashlight re-enabled after giving cash.")
			else:
				data["real_flashlight_enabled"] = false
				data["real_flashlight_unlocked"] = false
		else:
			if data.get("real_flashlight_enabled", false):
				_print_once("[FlashlightManager] Real flashlight already unlocked — keeping ON.")
	else:
		_print_once("[FlashlightManager] Flashlight states loaded for %s %s" % [act, scene])

	# Apply loaded states to lights
	_update_lights()

	_print_once("[FlashlightManager] Initialized. Real flashlight unlocked: %s" % str(data["real_flashlight_unlocked"]))
	_save_json()

# ===================
# FLASHLIGHT CONTROL
# ===================
func unlock_real_flashlight() -> void:
	# Unlock the real flashlight permanently
	real_flashlight_unlocked = true
	_print_once("[FlashlightManager] Real flashlight UNLOCKED!")

func toggle_real_flashlight() -> void:
	# Toggle real flashlight if allowed
	if not can_use_real_flashlight():
		_print_once("[FlashlightManager] Real flashlight cannot be used yet.")
		return
	real_flashlight_enabled = !real_flashlight_enabled
	_update_lights()

func toggle_phone_flashlight() -> void:
	var act = data.get("current_act", "")
	var scene = data.get("current_scene", "")
	var first_unlock := false

	# Allow unlocking during Act 4 Scene 1
	if act == "act_4" and scene == "scene_1":
		if not data.get("phone_flashlight_enabled", false):
			data["phone_flashlight_enabled"] = true
			first_unlock = true
			_save_json()
			_print_once("[FlashlightManager] Phone flashlight unlocked during phone_main trigger.")

	# Prevent use if conditions not met
	if not can_use_phone_flashlight():
		_print_once("[FlashlightManager] Phone flashlight cannot be used yet.")
		return

	# Handle first unlock separately
	if first_unlock:
		_update_lights()
		return

	# Toggle on/off normally
	phone_flashlight_enabled = !phone_flashlight_enabled
	_save_json()
	_print_once("[FlashlightManager] Phone flashlight toggled: %s" % str(phone_flashlight_enabled))
	_update_lights()

func _update_lights() -> void:
	if player_real_flashlight:
		_fade_light(player_real_flashlight, real_flashlight_enabled)
	if player_phone_flashlight:
		_fade_light(player_phone_flashlight, phone_flashlight_enabled)

	if player_node and player_node.has_method("_play_animation"):
		player_node._play_animation(Vector2.ZERO)
	
	# Emit signal when phone flashlight turns ON
	if phone_flashlight_enabled:
		emit_signal("phone_flashlight_enabled_signal")


# ==========================================
# FADE EFFECT HANDLER
# ==========================================
func _fade_light(light: PointLight2D, turn_on: bool, duration: float = 0.3) -> void:
	if not light:
		return

	# Ensure visible if turning on
	if turn_on:
		light.visible = true

	# Kill any previous active tween
	if light.has_meta("fade_tween"):
		var old_tween = light.get_meta("fade_tween")
		if old_tween and old_tween.is_running():
			old_tween.kill()

	# Create new scene tree tween (Godot 4 way)
	var tween := get_tree().create_tween()
	light.set_meta("fade_tween", tween)

	var start_value := light.energy
	var end_value := 1.0 if turn_on else 0.0

	tween.tween_property(light, "energy", end_value, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if not turn_on:
		tween.finished.connect(func():
			light.visible = false)

# ===================
# SCENE TRACKING
# ===================
func set_current_scene(act: String, scene: String) -> void:
	# Save the current act and scene
	data["current_act"] = act
	data["current_scene"] = scene

	# Reset flashlight state at Act 3 Scene 1
	if act == "act_3" and scene == "scene_1":
		reset_flashlight_state()

	_save_json()

# ===================
# RESET
# ===================
func reset_flashlight_state() -> void:
	# Turn off both flashlights
	real_flashlight_enabled = false
	phone_flashlight_enabled = false
	_update_lights()
	_print_once("[FlashlightManager] Flashlights reset for Act 3 Scene 1.")

# ===================
# FLASHLIGHT PERMISSION LOGIC
# ===================
func can_use_real_flashlight() -> bool:
	# Check if the real flashlight can currently be used
	var act = data.get("current_act", "")
	var scene = data.get("current_scene", "")

	if act in ["act_1","act_2","act_3"]:
		return false

	if act == "act_4" and scene == "scene_1" and not real_flashlight_unlocked:
		return false

	if act == "act_4":
		var scene_number = int(scene.replace("scene_", ""))
		if scene_number >= 2:
			return SaveManager.has_given_lola_ising_cash()

	return real_flashlight_unlocked

func can_use_phone_flashlight() -> bool:
	# Check if the phone flashlight can currently be used
	var act = data.get("current_act", "")
	var scene = data.get("current_scene", "")

	if act in ["act_1", "act_2", "act_3"]:
		return false

	if act == "act_4" and scene == "scene_1":
		if data.get("phone_flashlight_enabled", false):
			return true
		else:
			return false

	if act == "act_4":
		var scene_number = int(scene.replace("scene_", ""))
		if scene_number >= 2:
			return true

	return false

# ===================
# JSON PERSISTENCE
# ===================
func _save_json() -> void:
	# Save current flashlight data to JSON file
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _load_json() -> void:
	# Load saved flashlight data or use defaults
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var parsed = JSON.parse_string(json_text)
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
				_print_once("[FlashlightManager] Flashlight state loaded from JSON.")
			file.close()
	else:
		_print_once("[FlashlightManager] JSON not found, using defaults.")


# ============================================================================ # 

func _print_once(msg: String) -> void:
	if msg != _last_debug_message:
		print(msg)
		_last_debug_message = msg
