# ProgressManager.gd

extends Node

const SAVE_FILE := "user://a4_testsssS.json"
#change file name para mareload yung mga dirts

# === STATE ===
var current_act: String = "act_4"
var current_scene: String = "scene_2"
var scenes_completed = {}   # {"dark_forest_dialogue_shown": true, ...}
var dirt_visible = {
	"dirt_1": true, "dirt_2": true, "dirt_3": true, "dirt_4": true,
	"dirt_5": true, "dirt_6": true, "dirt_7": true, "dirt_8": true
}
var key_collected = false
var house_enter_disabled = false
var grave_exit_enabled = false

func reset():
	print("🔄 ProgressManager: Resetting all Act 4 Scene 2 progress")
	scenes_completed.clear()
	dirt_visible = {
		"dirt_1": true, "dirt_2": true, "dirt_3": true, "dirt_4": true,
		"dirt_5": true, "dirt_6": true, "dirt_7": true, "dirt_8": true
	}
	key_collected = false
	house_enter_disabled = false
	grave_exit_enabled = false
	save_state()


# === Progress Helpers ===

func save_dialogue_shown(zone_name):
	scenes_completed["%s_dialogue_shown" % zone_name] = true
	save_state()

func is_dialogue_shown(zone_name):
	return scenes_completed.has("%s_dialogue_shown" % zone_name) and scenes_completed["%s_dialogue_shown" % zone_name]

func set_dirt_visible(dirt_name, visible):
	dirt_visible[dirt_name] = visible
	save_state()

func is_dirt_visible(dirt_name):
	return dirt_visible.has(dirt_name) and dirt_visible[dirt_name]

func set_key_collected(collected):
	key_collected = collected
	save_state()

func set_house_enter_disabled(disabled):
	house_enter_disabled = disabled
	save_state()

func set_grave_exit_enabled(enabled):
	grave_exit_enabled = enabled
	save_state()

# === JSON SAVE/LOAD ===

func save_state():
	var save_dict = {
		"current_act": current_act,
		"current_scene": current_scene,
		"scenes_completed": scenes_completed,
		"dirt_visible": dirt_visible,
		"key_collected": key_collected,
		"house_enter_disabled": house_enter_disabled,
		"grave_exit_enabled": grave_exit_enabled
	}
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))
		file.close()
		print("ProgressManager: Progress saved.")
	else:
		push_error("ProgressManager: Failed to open save file.")

func load_state():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file and file.get_length() > 0:
		var json_string = file.get_as_text()
		var loaded = JSON.parse_string(json_string)
		if typeof(loaded) == TYPE_DICTIONARY:
			current_act = loaded.get("current_act", current_act)
			current_scene = loaded.get("current_scene", current_scene)
			scenes_completed = loaded.get("scenes_completed", {})
			dirt_visible = loaded.get("dirt_visible", dirt_visible)
			key_collected = loaded.get("key_collected", false)
			house_enter_disabled = loaded.get("house_enter_disabled", false)
			grave_exit_enabled = loaded.get("grave_exit_enabled", false)
			print("ProgressManager: Progress loaded.")
		else:
			print("ProgressManager: Invalid JSON, starting fresh.")
	else:
		print("ProgressManager: No save file found, starting fresh.")
