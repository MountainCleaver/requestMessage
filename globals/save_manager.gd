extends Node

const SAVE_PATH := "user://saves.res"
const BACKUP_PATH := "user://saves.bak.res"

var game_save: SaveGameResource

var next_scene_path : String;

func _ready() -> void:
	SignalBus.act_num_scene_num_done.connect(_save_game_progress);
	load_game()

func _save_game_progress(act: String, scene: String, next_scene: String) -> void:
	print("go to saving screen")
	GameSceneManager._change_scene("res://scenes/game/saving_screen.tscn");
	next_scene_path = next_scene;
	mark_scene_finished(act, scene);

func load_game() -> void: # load saved gamews
	if FileAccess.file_exists(SAVE_PATH):
		game_save = load(SAVE_PATH) as SaveGameResource
		print("loading success")
	elif FileAccess.file_exists(BACKUP_PATH):
		# Recover from backup if main save is missing/corrupted
		print("Main save missing, loading backup.")
		game_save = load(BACKUP_PATH) as SaveGameResource
		save_game() # immediately restore main save
	else:
		game_save = SaveGameResource.new()
		save_game()

func save_game() -> void: # save game data to path
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
	
	print("saving game")


func save_game_next_scene() -> void:
	GameSceneManager._change_scene(next_scene_path);

# helper functions

func mark_scene_finished(act: String, scene: String) -> void: # update values in save game resource
	print("save finished scene")
	var scenes: Array = game_save.finished_scenes.get(act, [])
	if scene not in scenes:
		scenes.append(scene)
		game_save.finished_scenes[act] = scenes

func is_scene_finished(act: String, scene: String) -> bool:
	return scene in game_save.finished_scenes.get(act, [])
