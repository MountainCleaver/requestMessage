extends Node

# -------------------------------
# Flashlight Manager (autoload)
# -------------------------------

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

# -------------------------------
# Properties
# -------------------------------
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

# -------------------------------
# Initialization
# -------------------------------
func init(real_flash: PointLight2D, phone_flash: PointLight2D) -> void:
	player_real_flashlight = real_flash
	player_phone_flashlight = phone_flash
	_load_json()

	var act = data.get("current_act", "")
	var scene = data.get("current_scene", "")

	# Force OFF for early acts/scenes
	if (act in ["act_1","act_2","act_3"]) or (act == "act_4" and scene == "scene_1"):
		data["real_flashlight_enabled"] = false
		data["phone_flashlight_enabled"] = false
		print("[FlashlightManager] Disabled real flashlight for early acts/scenes.")

	_update_lights()
	print("[FlashlightManager] Initialized. Real flashlight unlocked:", data["real_flashlight_unlocked"])
	_save_json()

# -------------------------------
# Flashlight control
# -------------------------------
func unlock_real_flashlight() -> void:
	real_flashlight_unlocked = true
	print("[FlashlightManager] Real flashlight UNLOCKED!")

func toggle_real_flashlight() -> void:
	if not can_use_real_flashlight():
		print("[FlashlightManager] Real flashlight cannot be used yet!")
		return
	real_flashlight_enabled = !real_flashlight_enabled
	_update_lights()

func toggle_phone_flashlight() -> void:
	phone_flashlight_enabled = !phone_flashlight_enabled
	_update_lights()

func _update_lights() -> void:
	if player_real_flashlight:
		player_real_flashlight.visible = real_flashlight_enabled
	if player_phone_flashlight:
		player_phone_flashlight.visible = phone_flashlight_enabled

# -------------------------------
# Scene tracking
# -------------------------------
func set_current_scene(act: String, scene: String) -> void:
	data["current_act"] = act
	data["current_scene"] = scene

	# Auto-reset flashlights for Act 3 Scene 1
	if act == "act_3" and scene == "scene_1":
		reset_flashlight_state()

	_save_json()

# -------------------------------
# Reset
# -------------------------------
func reset_flashlight_state() -> void:
	real_flashlight_enabled = false
	phone_flashlight_enabled = false
	_update_lights()
	print("[FlashlightManager] Flashlights reset due to Act 3 Scene 1!")

# -------------------------------
# Flashlight permission logic
# -------------------------------
func can_use_real_flashlight() -> bool:
	var act = data.get("current_act", "")
	var scene = data.get("current_scene", "")

	# Early acts are always blocked
	if act in ["act_1","act_2","act_3"]:
		return false

	# Act 4 Scene 1: blocked only if not unlocked yet
	if act == "act_4" and scene == "scene_1":
		if not real_flashlight_unlocked:
			return false

	# Act 4 Scene 2+ : check if given cash to Lola Ising
	if act == "act_4":
		var scene_number = int(scene.replace("scene_", ""))
		if scene_number >= 2:
			return SaveManager.has_given_lola_ising_cash()

	# Default fallback: must be unlocked
	return real_flashlight_unlocked


# -------------------------------
# JSON Persistence
# -------------------------------
func _save_json() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("[FlashlightManager] Saved flashlight state.")

func _load_json() -> void:
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var parsed = JSON.parse_string(json_text)
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
				print("[FlashlightManager] Loaded flashlight state from JSON:", data)
			else:
				print("[FlashlightManager] Failed to parse JSON, using defaults.")
			file.close()
	else:
		print("[FlashlightManager] JSON file not found, using defaults.")
