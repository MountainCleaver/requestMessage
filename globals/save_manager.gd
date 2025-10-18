extends Node

const SAVE_PATH := "user://saves.res"
const BACKUP_PATH := "user://saves.bak.res"

var game_save: SaveGameResource
var next_scene_path: String
var current_username: String = "" 

func _ready() -> void:
	SignalBus.act_num_scene_num_done.connect(_save_game_progress)
	load_game()

	Session.connect("session_loaded", Callable(self, "_on_session_loaded"))

func _on_session_loaded():
	current_username = Session.username
	load_game()


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
		save_game()  # Immediately restore main save
	else:
		game_save = SaveGameResource.new()
		save_game()

func save_game() -> void:
	print("saving game")
	# Backup old save if it exists
	if FileAccess.file_exists(SAVE_PATH):
		var copy_err := DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
		if copy_err != OK:
			push_error("Failed to create backup: %s" % copy_err)
	# Save new file
	var error := ResourceSaver.save(game_save, SAVE_PATH)
	if error != OK:
		push_error("Failed to save game: %s" % error)

func save_game_next_scene() -> void:
	GameSceneManager._change_scene(next_scene_path)


func mark_scene_finished(act: String, scene: String) -> void:
	
	# Update local save
	var scenes: Array = game_save.finished_scenes.get(act, [])
	if scene not in scenes:
		scenes.append(scene)
	game_save.finished_scenes[act] = scenes
	save_game()  # Save locally
	
	# Track save in admin (total saves)
	track_save()
	
	# Track progress per player using user_ID
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
	
func save_moral_choice(act_scene: String, choice: String)-> void:
	game_save.choices[act_scene] = choice
	match choice:
		"restless":
			game_save.karma -= 1
		"relief":
			game_save.karma += 1
	
func get_moral_choice(act_scene: String) -> String:
	if act_scene in game_save.choices:
		return game_save.choices[act_scene]
	return ""

func took_meds()->void:
	game_save.meds_taken += 1
	print("Uminom ng gamot, current na na-inom: " + str(game_save.meds_taken))
	# save pag tapos ng scene, not right after

func get_count_meds_taken()->int:
	return game_save.meds_taken
