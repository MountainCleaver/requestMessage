extends Node

var SAVE_PATH: String = ""
var BACKUP_PATH: String = ""

var game_save: SaveGameResource
var next_scene_path: String
var current_username: String = ""
var current_user_id: int = 0
var current_slot: int = 0
var play_timer: Timer
var play_start_time: int = 0
var save_call_count := 0 
var has_saved_this_session: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if SignalBus.act_num_scene_num_done.is_connected(_save_game_progress):
		SignalBus.act_num_scene_num_done.disconnect(_save_game_progress)
	SignalBus.act_num_scene_num_done.connect(_save_game_progress)

	if not Session.is_connected("session_loaded", Callable(self, "_on_session_loaded")):
		Session.connect("session_loaded", Callable(self, "_on_session_loaded"))

	if Session.logged_in:
		_on_session_loaded()

	if play_timer == null:
		play_timer = Timer.new()
		play_timer.wait_time = 1.0
		play_timer.autostart = true
		play_timer.one_shot = false
		play_timer.timeout.connect(_on_play_timer_tick)
		add_child(play_timer)

	play_start_time = Time.get_unix_time_from_system()


func _on_session_loaded():
	print("[SaveManager] _on_session_loaded() triggered for user:", Session.username)
	current_username = Session.username
	current_user_id = Session.user_ID
	_set_save_paths()
	if FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] Existing save found for", current_username)
		load_game()
	else:
		print("[SaveManager] No save found for", current_username, "— creating new save.")
		reset_save_state()
	if Session.user_ID != 0:
		_sync_online_save()

func _on_play_timer_tick() -> void:
	if game_save:
		game_save.playtime_seconds += 1

func _set_save_paths():
	if current_slot < 1 or current_slot > 3:
		current_slot = 1 
	var user_folder = "user://users/%s_%d/slot_%d" % [Session.username, Session.user_ID, current_slot]
	var users_dir = DirAccess.open("user://users")
	if not users_dir:
		var root_dir = DirAccess.open("user://")
		if root_dir:
			root_dir.make_dir("users")
			users_dir = DirAccess.open("user://users")
	var user_dir = DirAccess.open("user://users/%s_%d" % [Session.username, Session.user_ID])
	if not user_dir:
		users_dir.make_dir("%s_%d" % [Session.username, Session.user_ID])
	var slot_dir = DirAccess.open(user_folder)
	if not slot_dir:
		users_dir.make_dir("%s_%d/slot_%d" % [Session.username, Session.user_ID, current_slot])
	SAVE_PATH = "%s/save.res" % user_folder
	BACKUP_PATH = "%s/backup.res" % user_folder
	print("[SaveManager] Save path set to:", SAVE_PATH)
	print("[SaveManager] Backup path set to:", BACKUP_PATH)

func _save_game_progress(act: String, scene: String, next_scene: String) -> void:
	save_call_count += 1

	if not has_saved_this_session:
		has_saved_this_session = true
		track_save()
		print("[TrackSave] FIRST SAVE this session (Call: ", save_call_count, ")")
	else:
		print("[SaveManager] Subsequent save but not tracked (Call: ", save_call_count, ")")

	mark_scene_finished(act, scene)
	_set_current_scene_from_path(next_scene)

	var next_act = game_save.current_act
	var next_scene_name = game_save.current_scene
	if not game_save.finished_scenes.has(next_act):
		game_save.finished_scenes[next_act] = []
	if next_scene_name not in game_save.finished_scenes[next_act]:
		game_save.finished_scenes[next_act].append(next_scene_name)

	if current_user_id != 0:
		_push_online_save(act, scene)

	save_game()

	next_scene_path = next_scene
	GameSceneManager._change_scene("res://scenes/game/saving_screen.tscn")
	print("[SaveManager] Progress saved successfully → Next Scene:", next_scene_path)


func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		game_save = load(SAVE_PATH) as SaveGameResource
		print("loading success")
	elif FileAccess.file_exists(BACKUP_PATH):
		print("Main save missing, loading backup.")
		game_save = load(BACKUP_PATH) as SaveGameResource
		save_game()
	else:
		game_save = SaveGameResource.new()
		save_game()

func save_game() -> void:
	var now = Time.get_unix_time_from_system()
	var elapsed = now - play_start_time
	game_save.playtime_seconds += elapsed
	play_start_time = now
	print("saving game")
	if FileAccess.file_exists(SAVE_PATH):
		var copy_err := DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
		if copy_err != OK:
			push_error("Failed to create backup: %s" % copy_err)
	var error := ResourceSaver.save(game_save, SAVE_PATH)
	if error != OK:
		push_error("Failed to save game: %s" % error)

func reset_save_state():
	print("[SaveManager] Resetting local save state (keeping username and paths).")
	game_save = SaveGameResource.new()
	game_save.current_act = "act_1"
	game_save.current_scene = "scene_1"
	game_save.finished_scenes = {"act_1": ["scene_1"]}
	game_save.playtime_seconds = 0
	game_save.date_created = Time.get_unix_time_from_system()

func save_game_next_scene() -> void:
	GameSceneManager._change_scene(next_scene_path)

func mark_scene_finished(act: String, scene: String) -> void:
	var scenes: Array = game_save.finished_scenes.get(act, [])
	if scene not in scenes:
		scenes.append(scene)
	game_save.finished_scenes[act] = scenes
	game_save.current_act = act
	game_save.current_scene = scene
	save_game()
	if Session.user_ID != 0:
		_push_online_save(act, scene) 
	else:
		print("Warning: user_ID is 0. Progress not sent to API.")

func is_scene_finished(act: String, scene: String) -> bool:
	return scene in game_save.finished_scenes.get(act, [])

func has_save() -> bool:
	var path := ""
	if FileAccess.file_exists(SAVE_PATH):
		path = SAVE_PATH
	elif FileAccess.file_exists(BACKUP_PATH):
		path = BACKUP_PATH
	else:
		return false
	var test_save = load(path) as SaveGameResource
	return test_save != null

func _save_has_finished_scenes(save_data: SaveGameResource) -> bool :
	if not save_data:
		return false;
	if save_data.current_scene != "" or save_data.current_act != "":
		return true;
	for act in save_data.finished_scenes:
		var scene_array : Array = save_data.finished_scenes[act]
		if scene_array.size() > 0:
			return true;
	if save_data.choices and save_data.choices.size() > 0:
		return true;
	if save_data.karma != 0:
		return true;
	return false;

func track_save() -> void:
	var url = "https://requestmessage-admin.onrender.com/api/track_save.php"
	var request = HTTPRequest.new()
	add_child(request)
	var data = {
		"save": true,
		"user_id": current_user_id,
		"username": current_username,
		"timestamp": Time.get_datetime_string_from_system()
	}
	var json = JSON.stringify(data)
	request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		json
	)

func set_player_username(username: String) -> void:
	current_username = username
	print("Current username set to: ", current_username)
	
func track_ending(user_id: int, current_scene_path: String) -> void:
	var ending_name := ""

	if current_scene_path == "res://scenes/game/act_6/scene_2.1/finally_at_rest.tscn":
		ending_name = "Good Ending"
	elif current_scene_path == "res://scenes/game/act_6/scene_2.2/unending_guilt.tscn":
		ending_name = "Bad Ending"

	if ending_name != "":
		print("Detected", ending_name, "for user", user_id)

		var request := HTTPRequest.new()
		add_child(request)

		var url := "https://requestmessage-admin.onrender.com/api/track_endings.php"
		var data := {
			"user_id": user_id,
			"ending_name": ending_name,
			"achieved_at": Time.get_datetime_string_from_system(),
			"playtime_seconds": game_save.playtime_seconds
		}

		var json_data := JSON.stringify(data)
		request.request(
			url,
			["Content-Type: application/json"],
			HTTPClient.METHOD_POST,
			json_data
		)

func switch_account(new_username: String) -> void:
	current_username = new_username
	print("SaveManager: Switched account to: ", current_username)
	load_game() 

func set_last_played_slot(slot_index: int) -> void:
	current_slot = slot_index
	if game_save:
		game_save.last_played_slot = slot_index
	save_game()

func save_moral_choice(act_scene: String, choice: String) -> void:
	if not game_save:
		game_save = SaveGameResource.new()

	if act_scene in game_save.choices:
		var old_choice = game_save.choices[act_scene]
		if old_choice == "restless":
			game_save.karma += 1
		elif old_choice == "relief":
			game_save.karma -= 1
		print("[SaveManager] Scene replay detected. Resetting old moral choice:", old_choice)
	
	game_save.choices[act_scene] = choice
	
	match choice:
		"restless":
			game_save.karma -= 1
		"relief":
			game_save.karma += 1
	
	print("[SaveManager] New moral choice saved:", act_scene, "=", choice)
	print("[SaveManager] Current Karma:", game_save.karma)

	save_game_with_backup()

func save_game_with_backup() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var copy_err := DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
		if copy_err != OK:
			push_error("Failed to create backup before saving moral choice: %s" % copy_err)
	
	var save_err := ResourceSaver.save(game_save, SAVE_PATH)
	if save_err != OK:
		push_error("Failed to save game after moral choice: %s" % save_err)
	else:
		print("[SaveManager] Moral choice saved successfully with backup.")

func get_moral_choice(act_scene: String) -> String:
	if act_scene in game_save.choices:
		return game_save.choices[act_scene]
	return ""

func reset_all_moral_choices() -> void:
	game_save.choices.clear()
	game_save.karma = 0
	save_game()
	print("[SaveManager] All moral choices and karma reset.")

func recalc_meds_taken() -> void:
	var count := 0
	for act_scene in game_save.meds_finished_scenes.keys():
		if game_save.meds_finished_scenes[act_scene] == "took":
			count += 1
	game_save.meds_taken = count

func took_meds(act_scene: String) -> void:
	var prev_choice = game_save.meds_finished_scenes.get(act_scene, "")
	
	if prev_choice == "took":
		print("[SaveManager] Already took meds in this scene, not incrementing.")
		return
	elif prev_choice == "missed":
		print("[SaveManager] Overwriting previous missed choice with took.")

	game_save.meds_finished_scenes[act_scene] = "took"

	recalc_meds_taken()

	print("Uminom ng gamot, current na na-inom: " + str(game_save.meds_taken))
	save_game()

func missed_meds(act_scene: String) -> void:
	var prev_choice = game_save.meds_finished_scenes.get(act_scene, "")
	
	if prev_choice == "missed":
		print("[SaveManager] Already missed meds in this scene, not decrementing.")
		return
	elif prev_choice == "took":
		print("[SaveManager] Overwriting previous took choice with missed.")

	game_save.meds_finished_scenes[act_scene] = "missed"

	recalc_meds_taken()

	print("Hindi uminom ng gamot, current count: " + str(game_save.meds_taken))
	save_game()

func get_count_meds_taken() -> int:
	return game_save.meds_taken

func mark_scene_finished_for_meds(act_scene: String, choice: String) -> void:
	# choice should be "took" or "missed"
	if not game_save.meds_finished_scenes:
		game_save.meds_finished_scenes = {}
	
	game_save.meds_finished_scenes[act_scene] = choice
	print("[SaveManager] Meds scene marked as finished:", act_scene, "Choice:", choice)

func is_scene_finished_from_meds(act_scene: String) -> bool:
	return game_save.meds_finished_scenes.has(act_scene) and game_save.meds_finished_scenes[act_scene] != ""

func reset_all_meds() -> void:
	if not game_save:
		game_save = SaveGameResource.new()

	game_save.meds_finished_scenes.clear()
	game_save.meds_taken = 0
	print("[SaveManager] All meds data reset.")
	save_game()

func set_given_lola_ising_cash(value: bool) -> void:
	if not game_save:
		game_save = SaveGameResource.new()
		
	print("[SaveManager] Setting given_lola_ising_cash to:", value)
	game_save.choices["given_lola_ising_cash"] = value
	save_game()
	print("[SaveManager] given_lola_ising_cash saved successfully via choices dictionary!")

func has_given_lola_ising_cash() -> bool:
	if not game_save:
		game_save = SaveGameResource.new()
	
	if "given_lola_ising_cash" in game_save.choices:
		var val = game_save.choices["given_lola_ising_cash"]
		print("[SaveManager] Checking given_lola_ising_cash:", val)
		return val
	else:
		print("[SaveManager] No saved flag yet for lola_ising, returning false.")
		return false

func reset_lola_ising_progress() -> void:
	if not game_save:
		game_save = SaveGameResource.new()
	
	if "given_lola_ising_cash" in game_save.choices:
		game_save.choices.erase("given_lola_ising_cash")
		print("[SaveManager] Removed old given_lola_ising_cash flag.")
	
	var act := "act_3"
	var scene := "scene_1" 
	if act in game_save.finished_scenes and scene in game_save.finished_scenes[act]:
		game_save.finished_scenes[act].erase(scene)
	
	save_game()

func has_received_real_flashlight() -> bool:

	var lola_cash_given = has_given_lola_ising_cash()
	var scene_done = is_scene_finished("act_3", "scene_1")

	return lola_cash_given or scene_done

func get_total_karma() -> int:
	if not game_save:
		return 0
	
	var total := 0
	for act_scene in game_save.choices.keys():
		var choice = game_save.choices[act_scene]
		match choice:
			"restless":
				total -= 1
			"relief":
				total += 1
	return total

func can_unlock_achievement(act: String, scene: String) -> bool:
	if not game_save:
		return false

	# If the scene was marked as a game over, do NOT allow achievement
	if is_game_over(act, scene):
		print("[SaveManager] Cannot unlock achievement; game over in this scene.")
		return false

	# If scene is finished normally, achievement can unlock
	if is_scene_finished(act, scene):
		return true

	# Scene hasn't been finished yet: achievement can unlock
	return true

# Mark a game over in SaveManager so we can track it
func mark_game_over(act: String, scene: String) -> void:
	if not game_save:
		game_save = SaveGameResource.new()
		
	var key = "game_over_%s_%s" % [act, scene]
	game_save.choices[key] = true  # this is your flag
	save_game()
	print("[SaveManager] Game over recorded:", key)

func is_game_over(act: String, scene: String) -> bool:
	if not game_save:
		return false
	var key = "game_over_%s_%s" % [act, scene]
	return game_save.choices.has(key) and game_save.choices[key] == true

func reset_game_over(act: String = "", scene: String = "") -> void:
	if not game_save:
		game_save = SaveGameResource.new()
	
	if act == "" and scene == "":
		# Reset all game over flags
		var keys_to_remove := []
		for key in game_save.choices.keys():
			if key.begins_with("game_over_"):
				keys_to_remove.append(key)
		for key in keys_to_remove:
			game_save.choices.erase(key)
		print("[SaveManager] All game over flags cleared.")
	else:
		# Reset a specific scene
		var key = "game_over_%s_%s" % [act, scene]
		if game_save.choices.has(key):
			game_save.choices.erase(key)
			print("[SaveManager] Game over flag cleared for:", key)
	
	save_game()

# ===================
# ONLINE SAVE
# ===================
func _sync_online_save() -> void:
	print("[SaveManager] Syncing all online saves for user:", Session.user_ID)
	_sync_online_save_slot1()
	_sync_online_save_slot2()
	_sync_online_save_slot3()
	
func _sync_online_save_slot1() -> void:
	if Session.user_ID == 0:
		return
	var url = "https://requestmessage-admin.onrender.com/api/get_save.php?user_id=%d&slot=1" % Session.user_ID
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", Callable(self, "_on_online_save_fetched").bind(1))
	request.request(url)

func _sync_online_save_slot2() -> void:
	if Session.user_ID == 0:
		return
	var url = "https://requestmessage-admin.onrender.com/api/get_save.php?user_id=%d&slot=2" % Session.user_ID
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", Callable(self, "_on_online_save_fetched").bind(2))
	request.request(url)

func _sync_online_save_slot3() -> void:
	if Session.user_ID == 0:
		return
	var url = "https://requestmessage-admin.onrender.com/api/get_save.php?user_id=%d&slot=3" % Session.user_ID
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", Callable(self, "_on_online_save_fetched").bind(3))
	request.request(url)


func _on_online_save_fetched(result, response_code, headers, body, slot_num):
	if response_code != 200:
		print("[SaveManager] Failed to fetch online save for slot %d: %d" % [slot_num, response_code])
		return

	var body_text = body.get_string_from_utf8()
	var parse_result = JSON.parse_string(body_text)
	if typeof(parse_result) != TYPE_DICTIONARY:
		print("[SaveManager] Invalid JSON format for slot %d" % slot_num)
		return

	var json_result: Dictionary = parse_result

	if not json_result.has("result") or json_result["result"] == null:
		print("[SaveManager] No online save found for slot %d — skipping merge." % slot_num)
		return

	var online_save: Dictionary = json_result["result"]
	print("[SaveManager] Successfully fetched online save for slot %d" % slot_num)

	var slot_save := SaveGameResource.new()
	slot_save.current_act = online_save.get("current_act", "")
	slot_save.current_scene = online_save.get("current_scene", "")
	slot_save.finished_scenes = online_save.get("finished_scenes", {})

	var online_choices = online_save.get("choices", {})

	match typeof(online_choices):
		TYPE_DICTIONARY:
			slot_save.choices = online_choices.duplicate(true)
		TYPE_ARRAY:
			var choices_dict := {}
			for item in online_choices:
				choices_dict[str(item)] = true
			slot_save.choices = choices_dict
		_:
			print("[SaveManager] Warning: Invalid 'choices' format in online save (slot %d)." % slot_num)
			slot_save.choices = {}
			
	slot_save.karma = online_save.get("karma", 0)
	slot_save.playtime_seconds = online_save.get("playtime_seconds", 0)
	slot_save.meds_taken = online_save.get("meds_taken", 0)
	slot_save.date_created = online_save.get("date_created", Time.get_unix_time_from_system())

	var slot_dir_path = "user://users/%s_%d/slot_%d" % [Session.username, Session.user_ID, slot_num]
	var slot_path = slot_dir_path + "/save.res"

	if not DirAccess.dir_exists_absolute(slot_dir_path):
		DirAccess.make_dir_recursive_absolute(slot_dir_path)

	var err = ResourceSaver.save(slot_save, slot_path)
	if err != OK:
		print("[SaveManager] Failed to save slot %d → %s" % [slot_num, slot_path])
	else:
		print("[SaveManager] Slot %d online save saved locally → %s" % [slot_num, slot_path])

	if slot_num == current_slot:
		_merge_online_save(online_save)
		play_start_time = Time.get_unix_time_from_system()
		save_game()
		print("[SaveManager] Slot %d merged into active save." % slot_num)
		
	# ----- NEW: refresh achievement UI -----
	if Engine.has_singleton("Achievements"):
		var achievements_menu = Engine.get_singleton("Achievements")
		if achievements_menu:
			achievements_menu._refresh_achievements_from_save()

	SignalBus.online_save_merged.emit()

func _push_online_save(latest_act: String, latest_scene: String) -> void:
	if Session.user_ID == 0:
		return

	var url = "https://requestmessage-admin.onrender.com/api/update_save.php"
	var request = HTTPRequest.new()
	add_child(request)

	var data = {
		"user_id": Session.user_ID,
		"slot": current_slot,
		"save_data": game_save.to_dict(),
		"latest_act": latest_act,
		"latest_scene": latest_scene
	}

	print("[SaveManager] Sending online save for slot %d" % current_slot)

	var json_body = JSON.stringify(data)
	request.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, json_body)

func _merge_online_save(online_data: Dictionary) -> void:
	# Merge finished scenes
	for act in online_data.finished_scenes:
		if act in game_save.finished_scenes:
			for scene in online_data.finished_scenes[act]:
				if scene not in game_save.finished_scenes[act]:
					game_save.finished_scenes[act].append(scene)
		else:
			game_save.finished_scenes[act] = online_data.finished_scenes[act]

	# Merge choices
	for act_scene in online_data.choices:
		if act_scene not in game_save.choices:
			game_save.choices[act_scene] = online_data.choices[act_scene]

	# Merge karma and meds_taken
	game_save.karma = max(game_save.karma, online_data.karma)
	game_save.meds_taken = max(game_save.meds_taken, online_data.meds_taken)
	game_save.playtime_seconds = max(game_save.playtime_seconds, online_data.playtime_seconds)
	
	# ===== NEW: Merge unlocked achievements =====
	if online_data.has("unlocked_achievements"):
		for ach_id in online_data.unlocked_achievements:
			var id_int = int(ach_id)  # convert float to int
			if id_int not in game_save.unlocked_achievements:
				game_save.unlocked_achievements.append(id_int)
				
	# Update current act & scene to latest in finished_scenes
	var latest_act = ""
	var latest_scene = ""
	for act in game_save.finished_scenes.keys():
		for scene in game_save.finished_scenes[act]:
			latest_act = act
			latest_scene = scene
	if latest_act != "" and latest_scene != "":
		game_save.current_act = latest_act
		game_save.current_scene = latest_scene


func _set_current_scene_from_path(scene_path: String) -> void:
	var file_name = scene_path.get_file().get_basename()  # e.g. act_4_title_scene or danilo_room
	var parts = scene_path.get_base_dir().split("/")      # e.g. [res://, scenes, game, act_4, scene_2]

	var act_folder = ""
	var scene_name = "scene_1"

	# --- CASE 1: Title scenes (e.g. res://scenes/game/act_4_title_scene.tscn)
	if file_name.begins_with("act_") and file_name.contains("_title_scene"):
		var act_num = file_name.split("_")[1]  # get "4" from "act_4_title_scene"
		act_folder = "act_" + act_num
		scene_name = "scene_1"

	else:
		# --- CASE 2: Normal folder-based structure (e.g. act_4/scene_2/danilo_room.tscn)
		for part in parts:
			if part.begins_with("act_"):
				act_folder = part
			elif part.begins_with("scene_"):
				scene_name = part

	# --- fallback
	if act_folder == "":
		act_folder = "act_1"


	game_save.current_act = act_folder
	game_save.current_scene = scene_name
	save_game()
	print("[SaveManager] Current scene updated to:", act_folder, "-", scene_name)
	

func unlock_achievement(achievement_id: int) -> void:
	if not game_save:
		game_save = SaveGameResource.new()

	if not game_save.has("unlocked_achievements"):
		game_save.unlocked_achievements = []

	# Avoid duplicates
	if achievement_id in game_save.unlocked_achievements:
		print("[Achievements] Already unlocked:", achievement_id)
		return

	game_save.unlocked_achievements.append(achievement_id)
	save_game()

	print("[Achievements] Achievement unlocked:", achievement_id)

	# Send to online API
	if current_user_id != 0:
		_push_achievement_online(achievement_id)

func _push_achievement_online(achievement_id: int) -> void:
	var url = "https://requestmessage-admin.onrender.com/api/track_achievements.php"
	var request = HTTPRequest.new()
	add_child(request)

	var data = {
		"user_id": current_user_id,
		"unlocked_achievements": game_save.unlocked_achievements.map(func(x): return int(x)) # ensure ints
	}

	var json_data = JSON.stringify(data)
	request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		json_data
	)
	print("[Achievements] Sent achievements to server:", data)

	# Immediately merge locally to ensure UI consistency
	for ach in data["unlocked_achievements"]:
		if ach not in game_save.unlocked_achievements:
			game_save.unlocked_achievements.append(ach)

	save_game()


func fetch_online_achievements() -> void:
	if current_user_id == 0:
		print("[Achievements] No user logged in, cannot fetch online achievements.")
		return

	var url = "https://requestmessage-admin.onrender.com/api/get_achievements.php?user_id=%d" % current_user_id
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", Callable(self, "_on_achievements_fetched"))
	request.request(url)  # GET by default



func _on_achievements_fetched(result, response_code, headers, body):
	if response_code != 200:
		print("[Achievements] Failed to fetch achievements, code:", response_code)
		return

	var body_text = body.get_string_from_utf8()
	var parse_result = JSON.parse_string(body_text)  # returns Dictionary in Godot 4
	if typeof(parse_result) != TYPE_DICTIONARY:
		print("[Achievements] Failed to parse JSON, got:", typeof(parse_result))
		return

	if not parse_result.has("success") or not parse_result["success"]:
		print("[Achievements] API returned failure:", parse_result)
		return

	var online_achievements = parse_result.get("result", {}).get("unlocked_achievements", [])
	if online_achievements.size() == 0:
		print("[Achievements] No achievements found online.")
		return

	# Merge online achievements into local save
	if not game_save.unlocked_achievements:
		game_save.unlocked_achievements = []

	for ach_id in online_achievements:
		var id_int = int(ach_id)  # convert float/string to int
		if id_int not in game_save.unlocked_achievements:
			game_save.unlocked_achievements.append(id_int)

	save_game()
	print("[Achievements] Online achievements merged:", online_achievements)

	# Optional: Refresh achievements UI
	if Engine.has_singleton("Achievements"):
		var achievements_menu = Engine.get_singleton("Achievements")
		if achievements_menu:
			achievements_menu._refresh_achievements_from_save()
