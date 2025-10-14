extends Node2D

# === PRELOADS ===
const A_2S_4 = preload("res://dialogues/act_2/scene_4/a2s4.dialogue")
const LOCK_SCREEN = preload("res://scenes/game/lock_screen.tscn")
const NARRATION_INTRO = preload("res://scenes/game/act_2/scene_4/narration_screen.tscn")

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
	print("Act 2 Scene 4 initializing...")

	# Load game state
	if not GameState.load_game():
		push_error("Failed to load game state!")

	# Add objectives
	for objective in scene_objectives:
		ObjectiveManager.add_objective(objective["ID"], objective["text"])

	var narration = NARRATION_INTRO.instantiate()
	add_child(narration)
	narration.narration_finished.connect(_on_narration_finished)

	if SignalBus.has_signal("call_completed"):
		SignalBus.call_completed.connect(_on_call_completed)
	else:
		push_error("SignalBus missing 'call_completed' signal!")

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
			
			_start_outro_narration()

# === OUTRO NARRATION ===
func _start_outro_narration() -> void:
	var outro_narration = NARRATION_INTRO.instantiate()  
	var outro_text = """Phone in hand, Wendy understands the truth.
[shake rate=10 level=15][color=#ff5555][i]Danilo isn't resting[/i][/color][/shake], 
he's returning to face what he buried long ago.
[tornado radius=3 freq=15][color=#ff5555][b]And she fears what he will discover.[/b][/color][/tornado]"""
	
	outro_narration.set_narration_text(outro_text, true) 
	outro_narration.narration_finished.connect(_on_outro_narration_finished)
	add_child(outro_narration)

func _on_outro_narration_finished() -> void:
	
	scene_4_done()

# === SCENE COMPLETION FUNCTION ===
func scene_4_done() -> void:
	Hud.hide_objectives();
	
	SaveManager.game_save.current_act = "act_2"
	SaveManager.game_save.current_scene = "scene_4" # badly named I admit. this is for the 'continue' part in main menu
	SignalBus.act_num_scene_num_done.emit("act_2", "scene_4", "res://scenes/game/act_3/scene_1/act_3_scene_1.tscn") # caught in save manager
	Hud.clear_objectives();
	print("act 2 scene 4 is done")

# === CLEANUP ===
func _exit_tree() -> void:
	if SignalBus.has_signal("call_completed"):
		if SignalBus.call_completed.is_connected(_on_call_completed):
			SignalBus.call_completed.disconnect(_on_call_completed)
