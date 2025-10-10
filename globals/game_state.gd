extends Node

const SAVE_FILE := "user://save_chat_history.json"

# === BASIC STATE ===
var current_act: String = "act_1"
var current_scene: String = "scene_4"

# ===============================
# UTILITY: Get numeric scene index
# ===============================
func scene_index(scene_name: String) -> int:
	var parts = scene_name.split("_")
	if parts.size() < 2:
		return 0
	return int(parts[1])

# ===============================
# UTILITY: Add messages without duplicates
# ===============================
func add_messages_no_duplicates(target_history: Dictionary, source_history: Dictionary):
	for chat_name in target_history.keys():
		if source_history.has(chat_name):
			for msg in source_history[chat_name]:
				if msg not in target_history[chat_name]:
					target_history[chat_name].append(msg)

# ===============================
# SAVE GAME
# ===============================
func save_game():
	var data := {}
	
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		var existing = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(existing) == TYPE_DICTIONARY:
			data = existing

	if not data.has("acts"):
		data["acts"] = {}
	if not data["acts"].has(current_act):
		data["acts"][current_act] = {}
	
	data["acts"][current_act][current_scene] = {
		"chat_history": ChatManager.history.duplicate(true)
	}
	data["current_act"] = current_act
	data["current_scene"] = current_scene

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("Set to Act: %s, Scene: %s" % [current_act, current_scene])

# ===============================
# LOAD GAME
# ===============================
func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found. Starting fresh.")
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		print("Failed to parse save JSON!")
		return

	current_act = data.get("current_act", "act_1")
	current_scene = data.get("current_scene", "scene_4")

	var combined_history := {
		"wendy": [],
		"mira": [],
		"group_chat": [],
		"unknown_sender": []
	}

	if data.has("acts"):
		var acts_sorted = data["acts"].keys()
		acts_sorted.sort()

		for act_name in acts_sorted:
			# Skip acts after current
			if act_name > current_act:
				continue
			var act_data = data["acts"][act_name]
			var scenes_sorted = act_data.keys()
			scenes_sorted.sort_custom(func(a, b):
				return scene_index(a) - scene_index(b)
			)

			for scene_name in scenes_sorted:
				# Skip current/future scenes in current act
				if act_name == current_act and scene_index(scene_name) >= scene_index(current_scene):
					continue
				var scene_data = act_data[scene_name]
				if scene_data.has("chat_history"):
					add_messages_no_duplicates(combined_history, scene_data["chat_history"])

	# Ensure current scene exists
	if not data["acts"][current_act].has(current_scene):
		data["acts"][current_act][current_scene] = {
			"chat_history": {
				"wendy": [],
				"mira": [],
				"group_chat": [],
				"unknown_sender": []
			}
		}

	# Add current scene empty chats
	add_messages_no_duplicates(combined_history, data["acts"][current_act][current_scene]["chat_history"])

	ChatManager.history = combined_history.duplicate(true)
	print("Previous scene chats merged, current scene reset.")
	print("Current act: %s, scene: %s" % [current_act, current_scene])

# ===============================
# OVERWRITE CURRENT SCENE KEEP PREVIOUS
# ===============================
func overwrite_current_scene_keep_previous():
	if not FileAccess.file_exists(SAVE_FILE):
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		return

	if not data.has("acts"):
		data["acts"] = {}
	if not data["acts"].has(current_act):
		data["acts"][current_act] = {}

	# Reset only current scene
	data["acts"][current_act][current_scene] = {
		"chat_history": {
			"wendy": [],
			"mira": [],
			"group_chat": [],
			"unknown_sender": []
		}
	}

	# Write updated file
	var file_w = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file_w.store_string(JSON.stringify(data, "\t"))
	file_w.close()

	# Rebuild runtime ChatManager.history
	var combined_history := {
		"wendy": [],
		"mira": [],
		"group_chat": [],
		"unknown_sender": []
	}

	var acts_sorted = data["acts"].keys()
	acts_sorted.sort()

	for act_name in acts_sorted:
		if act_name > current_act:
			continue
		var act_data = data["acts"][act_name]
		var scenes_sorted = act_data.keys()
		scenes_sorted.sort_custom(func(a, b):
			return scene_index(a) - scene_index(b)
		)
		for scene_name in scenes_sorted:
			if act_name == current_act and scene_index(scene_name) >= scene_index(current_scene):
				continue
			var scene_data = act_data[scene_name]
			if scene_data.has("chat_history"):
				add_messages_no_duplicates(combined_history, scene_data["chat_history"])

	# Add current scene empty chats
	add_messages_no_duplicates(combined_history, data["acts"][current_act][current_scene]["chat_history"])

	ChatManager.history = combined_history.duplicate(true)
	print("Current scene overwritten, previous scenes loaded, future scenes excluded.")

# =========================
# QUICK RESET
# =========================
func reset_game():
	current_act = "act_1"
	current_scene = "scene_4"
	ChatManager.history = {
		"wendy": [], 
		"mira": [], 
		"group_chat": [], 
		"unknown_sender": []
	}
	print("Game reset successfully.")
