extends Area2D

const TARGET_SCENE := "res://scenes/game/act_5/scene_1/act_5_scene_5.tscn"
var teleporting := false

func _ready() -> void:
	body_entered.connect(_on_portal_entered)

func _on_portal_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	var note_script = preload("res://scenes/game/act_4/scene_4/note.gd")
	if not note_script.note_collected:
		print("Portal locked! Collect the paper first.")
		return

	print("Teleporting from Cliff to Forest")
	teleporting = true

	get_tree().set_meta("last_portal_name", name)
	get_tree().set_meta("last_portal_position", global_position)

	TransitionFade.transition()
	await get_tree().create_timer(0.15).timeout
	act_4_scene_4_done()
	
func act_4_scene_4_done() -> void:
	Hud.hide_objectives()
	Hud.clear_objectives()

	SaveManager.game_save.current_act = "act_4"
	SaveManager.game_save.current_scene = "scene_4"
	GameState.save_game()

	print("ACT 4 SCENE 4 DONE")

	# Emit signal to transition to the next scene
	SignalBus.act_num_scene_num_done.emit(
		"act_5", 
		"scene_1", 
		"res://scenes/game/act_5/scene_1/act_5_scene_5.tscn"
	)
