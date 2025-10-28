extends Node2D

var A_6S_2_1: Resource

@onready var player_danilo: CharacterBody2D = $hospital/player_danilo
@onready var animated_sprite_2d_danilo: AnimatedSprite2D = $hospital/player_danilo/AnimatedSprite2D
@onready var collision_shape_danilo: CollisionShape2D = $hospital/player_danilo/CollisionShape2D
@onready var wendy: CharacterBody2D = $hospital/wendy
@onready var animated_sprite_2d_wendy: AnimatedSprite2D = $hospital/wendy/AnimatedSprite2D

func _ready():
	_load_dialogue()
	await get_tree().process_frame   
	await _show_intro_narration()

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_6/scene_2.1/a6s2.1_en.dialogue"
	else:
		path = "res://dialogues/act_6/scene_2.1/a6s2.1.dialogue"
	
	A_6S_2_1 = load(path)

func _show_intro_narration() -> void:
	var lines = [
		"The villagers rush Danilo to the local hospital.",
        "Few days later, he awakens in a dimly lit room, Wendy at his side."
	]
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	await _run_cutscene()

func _run_cutscene() -> void:
	player_danilo.animation_locked = true
	player_danilo.can_move = false
	collision_shape_danilo.disabled = true

	animated_sprite_2d_danilo.play("sleep_hospital")
	animated_sprite_2d_wendy.play("idle_right")
	await get_tree().create_timer(2.0).timeout

	animated_sprite_2d_danilo.play("wake_hospital")
	await get_tree().create_timer(2.5).timeout

	animated_sprite_2d_danilo.play("idle_bed")

	var balloon = DialogueManager.show_dialogue_balloon(
		A_6S_2_1,
		"start",
		[self]
	)
	if balloon:
		balloon.tree_exited.connect(_on_dialogue_done)

func _on_dialogue_done():
	await _danilo_breathe_animation()
	await _end_scene()

func _danilo_breathe_animation() -> void:
	animated_sprite_2d_danilo.play("close_eyes")
	await get_tree().create_timer(0.8).timeout
	animated_sprite_2d_danilo.play("open_eyes")
	await get_tree().create_timer(0.6).timeout

func _end_scene() -> void:
	SignalBus.on_transition_finished.connect(_on_transition_finished, CONNECT_ONE_SHOT)
	TransitionFade.transition()

func _on_transition_finished():
	get_tree().change_scene_to_file("res://scenes/game/act_6/scene_2.1/good_ending.tscn")
