extends Node2D

@onready var playerNode := $player_danilo
@onready var animated_sprite_2d := $player_danilo/AnimatedSprite2D
@onready var marker_2d := $Marker2D
@onready var mira := $npc_mira

func _ready():
	start_cutscene()

func start_cutscene() -> void:
	playerNode.animation_locked = true
	playerNode.last_direction = Vector2.RIGHT
	$player_danilo/CollisionShape2D.disabled = true
	playerNode.can_move = false

	animated_sprite_2d.play("hometown_sleep")
	await get_tree().create_timer(1.5).timeout

	var balloon = DialogueManager.show_dialogue_balloon(
		load("res://dialogues/act_5/scene_7/a5s7.dialogue"),
		"mira_wake_up", [self]
	)
	if balloon:
		balloon.tree_exited.connect(_on_mira_wake_up_done)

func _on_mira_wake_up_done():
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
		load("res://dialogues/act_5/scene_7/a5s7.dialogue"),
		"start", [self]
	)
	if story_balloon:
		story_balloon.tree_exited.connect(_on_scene_7_dialogue_done)

func _on_scene_7_dialogue_done():
	act_5_scene_7_done()

func act_5_scene_7_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_7"
	GameState.save_game()

	print("ACT 5 SCENE 7 DONE")

	SignalBus.act_num_scene_num_done.emit(
		"act_5",
		"scene_8",
        "res://scenes/game/act_5_scene_8.tscn"
	)
