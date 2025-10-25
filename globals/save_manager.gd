extends Node

var SAVE_PATH: String = ""
var BACKUP_PATH: String = ""

var game_save: SaveGameResource
var next_scene_path: String
var current_username: String = "" 
var current_user_id: int = 0

func _ready() -> void:
	SignalBus.act_num_scene_num_done.connect(_save_game_progress)

	if not Session.is_connected("session_loaded", Callable(self, "_on_session_loaded")):
		Session.connect("session_loaded", Callable(self, "_on_session_loaded"))

	if Session.logged_in:
		_on_session_loaded()

func _on_session_loaded():
	print("[SaveManager] _on_session_loaded() triggered for user:", Session.username)
	current_username = Session.username
	current_user_id = Session.user_ID
	_set_save_paths()

	print("[SaveManager] Session loaded. Save path:", SAVE_PATH)

	if FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] Existing save found for", current_username)
		load_game()
		print("[SaveManager] Save data loaded for", current_username)
	else:
		print("[SaveManager] No save found for", current_username, "— creating new one.")
		reset_save_state()
		save_game() 

	
func _set_save_paths():
	var user_folder = "user://users/%s_%d" % [Session.username, Session.user_ID]

	var users_dir = DirAccess.open("user://users")
	if not users_dir:
		var root_dir = DirAccess.open("user://")
		if root_dir:
			var err = root_dir.make_dir("users")
			if err != OK:
				push_error("Failed to create 'users' folder")
				return
			users_dir = DirAccess.open("user://users")

	var user_dir = DirAccess.open(user_folder)
	if not user_dir:
		var err = users_dir.make_dir("%s_%d" % [Session.username, Session.user_ID])
		if err != OK:
			push_error("Failed to create folder for user: %s" % user_folder)
			return

	SAVE_PATH = "%s/save.res" % user_folder
	BACKUP_PATH = "%s/backup.res" % user_folder

	print("[SaveManager] Save path set to:", SAVE_PATH)
	print("[SaveManager] Backup path set to:", BACKUP_PATH)

		
func _save_game_progress(act: String, scene: String, next_scene: String) -> void:
	print("Saving progress for user:", current_username, "ID:", Session.user_ID, "Act:", act, "Scene:", scene)

	GameSceneManager._change_scene("res://scenes/game/saving_screen.tscn")
	next_scene_path = next_scene
	mark_scene_finished(act, scene)


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

func save_game_next_scene() -> void:
	GameSceneManager._change_scene(next_scene_path)

func mark_scene_finished(act: String, scene: String) -> void:
	var scenes: Array = game_save.finished_scenes.get(act, [])
	if scene not in scenes:
		scenes.append(scene)
	game_save.finished_scenes[act] = scenes
	save_game()
	
	track_save()

	if Session.user_ID != 0:
		track_save_progress(Session.user_ID, act, scene)
	else:
		print("Warning: user_ID is 0. Progress not sent to API.")

func is_scene_finished(act: String, scene: String) -> bool:
	return scene in game_save.finished_scenes.get(act, [])

func has_save() -> bool:
	if game_save:
		return _save_has_finished_scenes(game_save);
	
	var path : String = ""
	
	if FileAccess.file_exists(SAVE_PATH):
		path = SAVE_PATH
	elif FileAccess.file_exists(BACKUP_PATH):
		path = BACKUP_PATH
	else:
		return false
	
	var save_data = load(path) as SaveGameResource
	
	if not save_data:
		return false;
	
	return _save_has_finished_scenes(save_data)

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
	var data = { "save": true }  
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
	
func track_save_progress(user_id: int, act: String, scene: String) -> void:
	var url = "https://requestmessage-admin.onrender.com/api/update_progress.php"
	var request = HTTPRequest.new()
	add_child(request)

	var data = {
		"user_id": user_id,
		"act": act,
		"scene": scene,
		"timestamp": Time.get_datetime_string_from_system()
	}

	var json = JSON.stringify(data)
	request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		json
	)

func switch_account(new_username: String) -> void:
	current_username = new_username
	print("SaveManager: Switched account to: ", current_username)
	load_game() 
	
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
