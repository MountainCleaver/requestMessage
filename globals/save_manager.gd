extends Node

const SAVE_PATH := "user://saves.res"
const BACKUP_PATH := "user://saves.bak.res"

var game_save: SaveGameResource
var next_scene_path: String

func _ready() -> void:
	SignalBus.act_num_scene_num_done.connect(_save_game_progress)
	load_game()

func _save_game_progress(act: String, scene: String, next_scene: String) -> void:
	print("go to saving screen")
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
	print("save finished scene")
	var scenes: Array = game_save.finished_scenes.get(act, [])
	if scene not in scenes:
		scenes.append(scene)
	game_save.finished_scenes[act] = scenes
	# Track save in admin (total saves only)
	track_save()

func is_scene_finished(act: String, scene: String) -> bool:
	return scene in game_save.finished_scenes.get(act, [])

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)

func track_save() -> void:
	var url = "http://localhost/RequestMessage_Admin/api/track_save.php"
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
