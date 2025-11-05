extends Node2D

var A_5S_5: Resource

#SOUNDS
@onready var sfx_hit: AudioStreamPlayer = $SFX_HIT
@onready var sfx_crying: AudioStreamPlayer = $SFX_CRYING
@onready var sfx_rummage: AudioStreamPlayer = $SFX_RUMMAGE

@onready var camera_2d: Camera2D = $Camera2D
@onready var gino: CharacterBody2D = $"act_5_chapel/y-sorted/npc_gino_with_stick"
@onready var mateo: CharacterBody2D = $"act_5_chapel/y-sorted/mateo"

@onready var gino_animated_sprite_2d: AnimatedSprite2D = $"act_5_chapel/y-sorted/npc_gino_with_stick/AnimatedSprite2D"
@onready var mateo_animated_sprite_2d: AnimatedSprite2D = $"act_5_chapel/y-sorted/mateo/AnimatedSprite2D"

@onready var spawn_point: Marker2D = $markers/spawn_point
@onready var gino_thrash: Marker2D = $markers/gino_thrash
@onready var gino_hitting_spawn: Marker2D = $markers/gino_hitting_spawn

@onready var gino_turn: Area2D = $areas/gino_turn
@onready var mateo_turn: Area2D = $areas/mateo_turn

@onready var effects_anim: AnimationPlayer = $effects_anim

var is_hit: bool = false

func _ready() -> void:
	_load_dialogue()
	_spawn_mateo()
	await get_tree().create_timer(2.0).timeout
	_spawn_gino()
	
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_5/scene_5/a5s5_en.dialogue"
	else:
		path = "res://dialogues/act_5/scene_5/a5s5.dialogue"
	
	A_5S_5 = load(path)
	
func _spawn_mateo() -> void:
	await get_tree().create_timer(0.6).timeout
	mateo_animated_sprite_2d.play("idle_up")
	mateo.global_position = spawn_point.global_position
	await get_tree().create_timer(0.2).timeout
	mateo.direction = Vector2.UP

func _spawn_gino() -> void:
	await get_tree().create_timer(0.6).timeout
	gino_animated_sprite_2d.play("idle_up")
	gino.global_position = spawn_point.global_position
	await get_tree().create_timer(0.2).timeout
	gino.direction = Vector2.UP

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "mateo":
		return

	mateo.direction = Vector2.RIGHT
	await get_tree().create_timer(0.15).timeout

	mateo.direction = Vector2.UP
	await get_tree().create_timer(0.4).timeout

	mateo.direction = Vector2.ZERO
	await get_tree().process_frame
	mateo_animated_sprite_2d.play("idle_down")

	await get_tree().create_timer(0.2).timeout
	mateo.direction = Vector2.UP
	await get_tree().create_timer(0.2).timeout
	mateo.direction = Vector2.ZERO

	mateo_animated_sprite_2d.play("idle_down")

	await get_tree().create_timer(1.0).timeout
	mateo_animated_sprite_2d.play("crying")
	sfx_crying.play()
	mateo_turn.queue_free()


func _on_gino_turn_body_entered(body: Node2D) -> void:
	if body.name != "npc_gino_with_stick":
		return

	await get_tree().create_timer(0.5).timeout
	gino.direction = Vector2.ZERO
	gino_animated_sprite_2d.play("idle_right")

	DialogueManager.show_dialogue_balloon(A_5S_5, "mang_gino_being_a_bitch")
	gino_turn.queue_free()


func _on_vanish_body_entered(body: Node2D) -> void:
	if body.name == "mateo" and is_hit:
		mateo.queue_free()
		SignalBus.next_scene.emit("res://scenes/game/act_5/scene_5/act_5_scene_5_run_to_cliff.tscn")

func _hit_mateo(next_anim: String) -> void:
	print(gino.global_position)
	sfx_hit.play()
	gino_animated_sprite_2d.play("hitting")
	_camera_shake(0.7)
	await gino_animated_sprite_2d.animation_finished
	gino_animated_sprite_2d.play(next_anim)

func _camera_shake(wait: float = 0.0) -> void:
	await get_tree().create_timer(wait).timeout
	effects_anim.play("camera_shake")

func _spawn_gino_mateo_stuff() -> void:
	gino.global_position = gino_thrash.global_position
	gino_animated_sprite_2d.play("idle_down")

func _gino_thrashing_stuff() -> void:
	sfx_rummage.play()
	gino_animated_sprite_2d.play("idle_left")
	await get_tree().create_timer(0.2).timeout

	effects_anim.play("yeet_stuff")

	gino_animated_sprite_2d.play("idle_down")
	await get_tree().create_timer(0.1).timeout

	gino_animated_sprite_2d.play("idle_right")
	await get_tree().create_timer(0.2).timeout
	gino_animated_sprite_2d.play("idle_left")
	sfx_rummage.stop()

func _gino_respawn() -> void:
	gino.global_position = gino_hitting_spawn.global_position
	gino_animated_sprite_2d.play("idle_right")

func _mateo_run_again() -> void:
	mateo_animated_sprite_2d.play("idle_down")
	await get_tree().create_timer(0.2).timeout

	mateo.direction = Vector2.DOWN
	await get_tree().create_timer(0.2).timeout

	gino_animated_sprite_2d.play("idle_down")
	await get_tree().create_timer(0.1).timeout

	mateo.direction = Vector2.LEFT
	await get_tree().create_timer(0.1).timeout

	mateo.direction = Vector2.DOWN
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
