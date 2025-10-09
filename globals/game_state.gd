extends Node

const SAVE_FILE := "user://save_game.json"

# === SCENE STATE FLAGS ===
var current_act: String = "act_1"
var current_scene: String = "scene_4"

# === CHAT FLAGS ===
var checked_sched := false
var chat_objectives_added := false
var wendy_reply_shown := false
var mira_reply_shown := false
var wendy_opened := false
var mira_opened := false
var gc_opened := false
var unknown_sender_opened := false
var set1_objective_done := false
var objective8_added := false
var has_gone_home := false

# === PHONE STATE FLAGS ===
var phone_showing := false
var lock_screen_active := true
var phone_main_active := false
var chat_open := false

# ===============================
# SAVE GAME
# ===============================
func save_game():
	var data := {
		"current_act": current_act,
		"current_scene": current_scene,
		"checked_sched": checked_sched,
		"chat_objectives_added": chat_objectives_added,
		"wendy_reply_shown": wendy_reply_shown,
		"mira_reply_shown": mira_reply_shown,
		"wendy_opened": wendy_opened,
		"mira_opened": mira_opened,
		"gc_opened": gc_opened,
		"unknown_sender_opened": unknown_sender_opened,
		"set1_objective_done": set1_objective_done,
		"objective8_added": objective8_added,
		"has_gone_home": has_gone_home,
		
		# === phone state flags ===
		"phone_showing": phone_showing,
		"lock_screen_active": lock_screen_active,
		"phone_main_active": phone_main_active,
		"chat_open": chat_open,
	
		"chat_history": ChatManager.history.duplicate(true)
	}

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		var json := JSON.new()  # create JSON instance
		var pretty_text := json.stringify(data, "\t")
		file.store_string(pretty_text)
		file.close()
		print("Game saved successfully!")
	else:
		print("Failed to save game!")


# ===============================
# LOAD GAME
# ===============================
func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found. Starting fresh.")
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		print("Failed to open save file!")
		return

	var file_text = file.get_as_text()
	file.close()

	# Godot 4 JSON parsing
	var data: Dictionary = JSON.parse_string(file_text)
	if data == null:
		print("Failed to parse save JSON!")
		return

	# Restore all flags
	current_act = data.get("current_act", "act_1")
	current_scene = data.get("current_scene", "scene_4")
	checked_sched = data.get("checked_sched", false)
	chat_objectives_added = data.get("chat_objectives_added", false)
	wendy_reply_shown = data.get("wendy_reply_shown", false)
	mira_reply_shown = data.get("mira_reply_shown", false)
	wendy_opened = data.get("wendy_opened", false)
	mira_opened = data.get("mira_opened", false)
	gc_opened = data.get("gc_opened", false)
	unknown_sender_opened = data.get("unknown_sender_opened", false)
	set1_objective_done = data.get("set1_objective_done", false)
	objective8_added = data.get("objective8_added", false)
	has_gone_home = data.get("has_gone_home", false)
	phone_showing = data.get("phone_showing", false)
	lock_screen_active = data.get("lock_screen_active", true)
	phone_main_active = data.get("phone_main_active", false)
	chat_open = data.get("chat_open", false)


	# Restore chat history
	if data.has("chat_history"):
		ChatManager.history = data["chat_history"].duplicate(true)

	print("Game loaded successfully! Current scene: %s" % current_scene)


# =========================
# QUICK RESET (Optional)
# =========================
func reset_game():
	current_act = "act_1"
	current_scene = "scene_4"
	checked_sched = false
	chat_objectives_added = false
	wendy_reply_shown = false
	mira_reply_shown = false
	wendy_opened = false
	mira_opened = false
	gc_opened = false
	unknown_sender_opened = false
	set1_objective_done = false
	objective8_added = false
	has_gone_home = false
	ChatManager.history = {
		"wendy": [], 
		"mira": [], 
		"group_chat": [], 
		"unknown_sender": []
	}
	print("Game reset successfully.")
