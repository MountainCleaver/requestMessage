extends Node2D

var A_5S_5: Resource

@onready var npc_gino_with_stick: CharacterBody2D = $decorations/npc_gino_with_stick
@onready var player_mateo: CharacterBody2D = $decorations/player_mateo
@onready var game_over_area: Area2D = $decorations/player_mateo/game_over
@onready var game_over: TextureRect = $CanvasLayer/game_over
@onready var count_down: AnimationPlayer = $CanvasLayer/time/count_down
@onready var animation_player: AnimationPlayer = $tension/AnimationPlayer

@onready var sfx_boi: AudioStreamPlayer2D = $decorations/npc_gino_with_stick/SFX_BOI
@onready var bgm_tensed: AudioStreamPlayer2D = $decorations/npc_gino_with_stick/BGM_TENSED
@onready var bgm_gameover: AudioStreamPlayer = $BGM_GAMEOVER
@onready var bgm_chase: AudioStreamPlayer = $BGM_CHASE

func _ready() -> void:
	bgm_chase.play()
	_load_dialogue()
	player_mateo.force_cannot_move = true
	game_over.hide()
	count_down.play("count_down")
	
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_5/scene_5/a5s5_en.dialogue"
	else:
		path = "res://dialogues/act_5/scene_5/a5s5.dialogue"
	
	A_5S_5 = load(path)
	
func _on_game_over_body_entered(body: Node2D) -> void:
	bgm_gameover.play()
	bgm_chase.stop()
	sfx_boi.stop()
	bgm_tensed.stop()
	if body.name == "npc_gino_with_stick":
		player_mateo.set_physics_process(false)
		game_over.show()
		
		var tween = create_tween()
		tween.tween_property(game_over, "modulate:a", 1.0, 1.0)
		
		await get_tree().create_timer(2.0).timeout
		SignalBus.next_scene.emit(
			"res://scenes/game/act_5/scene_5/act_5_scene_5.tscn"
		)

func _start_chase() -> void:
	sfx_boi.play()
	bgm_tensed.play()
	SignalBus.start_chase.emit()
	player_mateo.force_cannot_move = false
	animation_player.play("tension_animator")
	# DialogueManager.show_dialogue_balloon(A_5S_5, "mateo_running")

func _on_chase_done_area_body_entered(body: Node2D) -> void:
	if body.name == "player_mateo":
		game_over_area.monitoring = false
		SignalBus.next_scene.emit(
			"res://scenes/game/act_5/scene_5/act_5_scene_5_chapel.tscn"
		)
		print("Chase done")
