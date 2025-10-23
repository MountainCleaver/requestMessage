extends Node2D

# === PRELOADS ===
const DARK_FOREST = preload("res://scenes/game/act_4/scene_2/grave_dark_forest.tscn")
const GRAVEYARD   = preload("res://scenes/game/act_4/scene_2/graveyard.tscn")
const SMALL_HUT   = preload("res://scenes/game/act_4/scene_2/small_hut.tscn")

# === NODES ===
@onready var locations: Node2D = $locations

# === VARIABLES ===
var current_scene: Node = null
var returning_from_hut := false

# === READY ===
func _ready() -> void:
	FlashlightManager.set_current_scene("act_4", "scene_2")
	FlashlightManager.enable_flashlight_by_cash()
	print("✅ Act 4 Controller Ready")

	if has_node("/root/ProgressManager"):
		ProgressManager.reset()

	load_dark_forest()

func _game_state_flow() -> void:
	# PUT THIS AT THE BEGINNING OF FUNC _READY
	GameState.load_game()
	GameState.current_act = "act_4"
	GameState.current_scene = "scene_2"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()

# === SCENE LOADERS ===
func load_dark_forest() -> void:
	_change_scene(DARK_FOREST)
	if current_scene.has_signal("entrance_triggered") and not current_scene.is_connected("entrance_triggered", Callable(self, "_on_forest_done")):
		current_scene.connect("entrance_triggered", Callable(self, "_on_forest_done"))
	print("🌲 Dark Forest loaded.")

func load_graveyard() -> void:
	_change_scene(GRAVEYARD)

	# Connect signals safely
	if current_scene.has_signal("key_found") and not current_scene.is_connected("key_found", Callable(self, "_on_key_found")):
		current_scene.connect("key_found", Callable(self, "_on_key_found"))
	if not current_scene.is_connected("hut_entered", Callable(self, "_on_hut_entered")):
		current_scene.connect("hut_entered", Callable(self, "_on_hut_entered"))
	if not current_scene.is_connected("grave_exit_triggered", Callable(self, "_on_grave_exit_triggered")):
		current_scene.connect("grave_exit_triggered", Callable(self, "_on_grave_exit_triggered"))

	# Restore scene progress if returning from hut or saved state
	if returning_from_hut or ProgressManager.scenes_completed.get("grave_visited", false):
		print("🔁 Returning to Graveyard — restoring state from ProgressManager.")
		_restore_graveyard_from_progress()
	else:
		print("🆕 First time in Graveyard — fresh start.")
		ProgressManager.scenes_completed["grave_visited"] = true
		ProgressManager.save_state()

func load_small_hut() -> void:
	_change_scene(SMALL_HUT)
	if current_scene.has_signal("hut_exit") and not current_scene.is_connected("hut_exit", Callable(self, "_on_hut_exit")):
		current_scene.connect("hut_exit", Callable(self, "_on_hut_exit"))
	print("🏠 Small Hut loaded.")

# === INTERNAL SCENE SWITCHER ===
func _change_scene(scene_res: PackedScene) -> void:
	if current_scene:
		current_scene.queue_free()
	current_scene = scene_res.instantiate()
	locations.add_child(current_scene)
	print("✅ Loaded scene:", scene_res.resource_path)

# === SIGNAL HANDLERS ===
func _on_forest_done() -> void:
	var player = _get_scene_player()
	if not player:
		push_error("Player not found in Dark Forest!")
		return
	player.can_move = false
	await TransitionFade.transition()
	await SignalBus.on_transition_finished
	await get_tree().process_frame
	load_graveyard()
	Hud.hide_objectives()

func _on_key_found() -> void:
	ProgressManager.set_key_collected(true)
	print("🗝️ Key collected and saved via ProgressManager.")

func _on_hut_entered() -> void:
	print("🏠 Entering Small Hut → transition start")
	ProgressManager.set_house_enter_disabled(true)

	var player = _get_scene_player()
	if not player:
		push_error("Player not found in Graveyard!")
		return

	player.can_move = false
	await TransitionFade.transition()
	await SignalBus.on_transition_finished
	await get_tree().process_frame
	load_small_hut()
	Hud.hide_objectives()

func _on_hut_exit() -> void:
	print("🚪 Exiting Small Hut → returning to Graveyard")
	await TransitionFade.transition()
	await SignalBus.on_transition_finished
	await get_tree().process_frame
	returning_from_hut = true
	load_graveyard()

	# Place player at house exit
	var player = _get_scene_player()
	if player:
		var exit_marker = current_scene.get_node_or_null("House_exit")
		if exit_marker:
			player.global_position = exit_marker.global_position
		player.can_move = true

	# Restore graveyard interactions from ProgressManager
	if current_scene.has_method("restore_graveyard_from_progress"):
		current_scene.restore_graveyard_from_progress()

	# Enable grave exit so player can leave
	if current_scene.has_method("enable_grave_exit"):
		current_scene.enable_grave_exit()

func _on_grave_exit_triggered() -> void:
	# only allow leaving after hut visit
	if not returning_from_hut:
		return

	ObjectiveManager.complete_objective(7)
	Hud.hide_objectives()
	Hud.clear_objectives()
	
	print("💾 Act 4 Scene 2 saved successfully via ProgressManager.")
	await TransitionFade.transition()
	SaveManager.game_save.current_act = "act_4"
	SaveManager.game_save.current_scene = "scene_2"
	GameState.save_game()
	print("ACT 4 SCENE 2 DONE")
	SignalBus.act_num_scene_num_done.emit(
		"act_4", 
		"scene_2", 
        "res://scenes/game/act_4/scene_3/act_4_scene_3.tscn"
	)

# === HELPERS ===
func _get_scene_player() -> CharacterBody2D:
	if current_scene and current_scene.has_node("y-sorted/player_danilo"):
		return current_scene.get_node("y-sorted/player_danilo")
	return null

# === RESTORE GRAVEYARD FROM SAVED STATE ===
func _restore_graveyard_from_progress() -> void:
	print("🪦 Restoring graveyard state from ProgressManager")

	if not current_scene:
		push_error("_restore_graveyard_from_progress called but current_scene is null")
		return
	
	# Restore dirt visibility / monitoring
	for dirt_name in ProgressManager.dirt_visible.keys():
		var visible = ProgressManager.dirt_visible[dirt_name]
		if current_scene.has_node("y-sorted") and current_scene.dirt_sprites.has(dirt_name):
			current_scene.dirt_sprites[dirt_name].visible = visible
		if current_scene.dirt_areas.has(dirt_name):
			current_scene.dirt_areas[dirt_name].monitoring = visible
			current_scene.dirt_areas[dirt_name].set_deferred("monitorable", visible)

	# Restore key
	if ProgressManager.key_collected:
		if current_scene.has_method("set_key_collected"):
			current_scene.set_key_collected(true)
		else:
			current_scene.key_collected = true
			current_scene.key_available = false
			if current_scene.has_node("y-sorted/player_danilo/question"):
				current_scene.mark.visible = false
			if current_scene.key:
				current_scene.key.visible = false

	# Disable grave entry if house was entered
	if ProgressManager.house_enter_disabled:
		if current_scene.has_node("Interactable/grave_entry"):
			current_scene.grave_entry.monitoring = false
			current_scene.grave_entry.set_deferred("monitorable", false)
			current_scene.hut_already_entered = true
		if current_scene.has_node("Interactable/house_enter"):
			current_scene.house_enter.monitoring = false
			current_scene.house_enter.set_deferred("monitorable", false)

func reset_graveyard_for_testing():
	print("🔄 Controller: Resetting graveyard scene and ProgressManager")
	if has_node("/root/ProgressManager"):
		ProgressManager.reset()

	if current_scene and current_scene.has_method("reset_graveyard_scene"):
		current_scene.reset_graveyard_scene()
	returning_from_hut = false
