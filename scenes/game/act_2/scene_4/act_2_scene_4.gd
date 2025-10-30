extends Node2D

# === PRELOADS ===
var A_2S_4: Resource
const LOCK_SCREEN = preload("res://scenes/game/lock_screen.tscn")
const NARRATION_PANEL = preload("res://helpers/narration_panel.tscn")

# === STATE VARIABLES ===
var wendy_opened := false
var wendy_reply_shown := false
var scene_objectives = [
	{"ID": 1, "text": "Call Danilo"},
	{"ID": 2, "text": "Call Mira"},
	{"ID": 3, "text": "End the call"},
]

# === READY FUNCTION ===
func _ready() -> void:
	FlashlightManager.set_current_scene("act_2", "scene_4")
	print("Act 2 Scene 4 initializing...")
	_load_dialogue()
	# Load game state
	if not GameState.load_game():
		push_error("Failed to load game state!")

	# Add objectives
	for objective in scene_objectives:
		ObjectiveManager.add_objective(objective["ID"], objective["text"])

	# Start narration using narration panel (same as scene 2)
	_start_intro_narration()

	# Connect signals
	if SignalBus.has_signal("call_completed"):
		SignalBus.call_completed.connect(_on_call_completed)
	else:
		push_error("SignalBus missing 'call_completed' signal!")

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_2/scene_4/a2s4_en.dialogue"
	else:
		path = "res://dialogues/act_2/scene_4/a2s4.dialogue"
	
	A_2S_4 = load(path)
	
# === INTRO NARRATION ===
func _start_intro_narration() -> void:
	await get_tree().process_frame
	var lines = [
		"Back in Manila, Wendy scrolls through her messages.",
		"Nothing from Danilo.",
		"No new messages. No sign of him.",
	]
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_on_narration_finished()


# === AFTER NARRATION FINISHES ===
func _on_narration_finished() -> void:
	print("Narration finished — starting dialogue.")
	if not DialogueManager.show_dialogue_balloon(A_2S_4, "start"):
		push_warning("Failed to start dialogue after narration.")


# === OPEN PHONE ===
func _open_wendy_phone() -> void:
	if not LOCK_SCREEN:
		push_error("LOCK_SCREEN scene not found!")
		return

	var lock_screen = LOCK_SCREEN.instantiate()
	lock_screen.pov_index = 1  # 0 = Danilo, 1 = Wendy
	add_child(lock_screen)
	print("Wendy's lock screen loaded.")


# === CALL COMPLETED HANDLER ===
func _on_call_completed(call_target: String) -> void:
	_load_dialogue()
	print("Call completed signal received for: ", call_target)
	
	match call_target:
		"danilo":
			ObjectiveManager.complete_objective(1)
			print("Danilo call objective completed")
			
		"mira":
			ObjectiveManager.complete_objective(2)
			print("Mira call objective completed")
			
			Hud.hide_objectives()
			Hud.clear_objectives()
			Hud.phone_outro()
			
			TransitionFade.transition()
			await SignalBus.on_transition_finished
			_start_outro_narration()


# === OUTRO NARRATION ===
func _start_outro_narration() -> void:
	await get_tree().process_frame
	var lines = [
		"Phone in hand, Wendy understands the truth.",
		"[shake rate=10 level=15][color=#ff5555]Danilo isn't resting.[/color][/shake]", 
		"He's returning to face what he buried long ago.",
		"[tornado radius=3 freq=15][color=#ff5555]And she fears what he will discover.[/color][/tornado]"
	]
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	_on_outro_narration_finished()


# === OUTRO DONE ===
func _on_outro_narration_finished() -> void:
	scene_4_done()


# === SCENE COMPLETION FUNCTION ===
func scene_4_done() -> void:
	Hud.hide_objectives()
	
	SaveManager.game_save.current_act = "act_2"
	SaveManager.game_save.current_scene = "scene_4"
	SaveManager.save_game()
	SignalBus.act_num_scene_num_done.emit(
		"act_2",
		"scene_4",
		"res://scenes/game/act_3_title_scene.tscn"
	)
	
	Hud.clear_objectives()
	print("Act 2 Scene 4 is done")


# === CLEANUP ===
func _exit_tree() -> void:
	if SignalBus.has_signal("call_completed"):
		if SignalBus.call_completed.is_connected(_on_call_completed):
			SignalBus.call_completed.disconnect(_on_call_completed)
