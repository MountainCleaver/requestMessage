extends Node2D

@onready var playerNode := $player_danilo
@onready var animated_sprite_2d := $player_danilo/AnimatedSprite2D
@onready var marker_2d := $Marker2D
@onready var mira := $npc_mira
var A_5S_7: Resource

var _scene_exiting := false  # <-- ADD FLAG

func _ready():
	# Detect exit to main menu
	SignalBus.next_scene.connect(_on_scene_change)
	
	FlashlightManager.set_current_scene("act_5", "scene_7")
	FlashlightManager.disable_flashlights()
	_load_dialogue()
	start_cutscene()

func _on_scene_change(path: String) -> void:
	# If going back to main menu, mark as exiting
	if path == "res://scenes/menu/menu_main.tscn":
		_scene_exiting = true

func start_cutscene() -> void:
	playerNode.animation_locked = true
	playerNode.last_direction = Vector2.RIGHT
	$player_danilo/CollisionShape2D.disabled = true
	playerNode.can_move = false

	animated_sprite_2d.play("hometown_sleep")
	await get_tree().create_timer(1.5).timeout

	var story_balloon = DialogueManager.show_dialogue_balloon(
		A_5S_7,
		"mira_wake_up", [self]
	)
	if story_balloon:
		story_balloon.tree_exited.connect(_on_mira_wake_up_done)

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_5/scene_7/a5s7_en.dialogue"
	else:
		path = "res://dialogues/act_5/scene_7/a5s7.dialogue"
	A_5S_7 = load(path)

func _on_mira_wake_up_done():
	# Skip if exiting
	if _scene_exiting:
		print("Skipped dialogue progression because exiting to main menu.")
		return

	animated_sprite_2d.play("hometown_wake")
	await get_tree().create_timer(1.0).timeout

	playerNode.position = marker_2d.position
	animated_sprite_2d.play("idle_right")
	await get_tree().create_timer(0.7).timeout

	playerNode.last_direction = Vector2.UP
	animated_sprite_2d.play("idle_up")
	$player_danilo/CollisionShape2D.disabled = false
	playerNode.animation_locked = false
	playerNode.can_move = false

	var story_balloon = DialogueManager.show_dialogue_balloon(
		A_5S_7,
		"start", [self]
	)
	
	if story_balloon:
		story_balloon.tree_exited.connect(_on_scene_7_dialogue_done)

func _on_scene_7_dialogue_done():
	# Skip if exiting
	if _scene_exiting:
		print("Skipped save because exiting to main menu.")
		return

	act_5_scene_7_done()

func act_5_scene_7_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_7"
	SaveManager.save_game()
	GameState.save_game()

	print("ACT 5 SCENE 7 DONE")

	SignalBus.act_num_scene_num_done.emit(
		"act_5",
		"scene_7",
		"res://scenes/game/act_5/scene_8/act_5_scene_8.tscn"
	)
		
 