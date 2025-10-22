extends Node2D

@onready var player_danilo: CharacterBody2D = $"y-sorted/player_danilo"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_2d: Camera2D = $"y-sorted/player_danilo/Camera2D"
@onready var npc_shadowy_ghost: CharacterBody2D = $"y-sorted/npc_shadowy_ghost"

# dream aesthetics
@onready var fog: ParallaxBackground = $fog
@onready var glimmering_light: Sprite2D = $glimmering_light
@onready var fog_ambience: Sprite2D = $fog_ambience
@onready var void_fx: Sprite2D = $"y-sorted/player_danilo/void"
@onready var blocking_trees: TileMapLayer = $"y-sorted/blocking_trees"

# markers
@onready var camera_for_ghost: Marker2D = $camera_for_ghost

# areas
@onready var see_light: Area2D = $areas/see_light
@onready var vanish: Area2D = $areas/vanish
@onready var ghost_flee: Area2D = $areas/ghost_flee

# preloads
const A_3S_4 = preload("uid://15o68hvrk4n0")

# flags
var in_dialogue : bool = false
var void_appeance_done : bool = false
var fog_and_void_gone : bool = false

func _ready() -> void:
	blocking_trees.hide()
	blocking_trees.collision_enabled = false
	DialogueManager.show_dialogue_balloon(A_3S_4, "start")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("arrow_right"):
		
		if void_appeance_done and not fog_and_void_gone:
			if in_dialogue:
				return
		
			in_dialogue = true
			DialogueManager.show_dialogue_balloon(A_3S_4, "facing_void")
		
func _void_appear()->void:
	await get_tree().create_timer(1.0).timeout
	animation_player.play("void_appear")
	await animation_player.animation_finished
	_void_pulse()
	void_appeance_done = true

func _void_pulse()->void:
	animation_player.play("void_pulsing")

func _on_see_light_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		DialogueManager.show_dialogue_balloon(A_3S_4, "saw_light")

func _on_vanish_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return

	fog_and_void_gone = true
	
	_remove_dream_elements()
	
	blocking_trees.show()
	blocking_trees.collision_enabled = true
	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue_balloon(A_3S_4, "reminisce")



func _tween_camera_to_ghost() -> void:
	var camera: Camera2D = camera_2d
	var tween = create_tween()
	# Smoothly move the camera toward the ghost marker
	tween.tween_property(
		camera,
		"global_position",
		camera_for_ghost.global_position,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Wait for first tween to finish before returning
	await tween.finished
	# Small pause for cinematic effect
	await get_tree().create_timer(1.0).timeout
	# Tween camera back to the player
	var return_tween = create_tween()
	return_tween.tween_property(
		camera,
		"global_position",
		player_danilo.global_position,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await return_tween.finished


func _on_ghost_flee_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		player_danilo.force_cannot_move = true
		_ghost_flee_1()


func _ghost_flee_1 () ->void:
	npc_shadowy_ghost.direction = Vector2.UP
	$"y-sorted/player_danilo/AnimationPlayer".play("appear")
func _ghot_turn_left () -> void:
	npc_shadowy_ghost.direction = Vector2.LEFT
	await get_tree().create_timer(1.0).timeout
	player_danilo.force_cannot_move = false

func _remove_dream_elements() -> void:
	animation_player.play("dream_elements_vanish")
	await animation_player.animation_finished
	vanish.queue_free()
	fog.queue_free()
	fog_ambience.queue_free()
	glimmering_light.queue_free()
	void_fx.queue_free()


func _on_ghost_turn_left_body_entered(body: Node2D) -> void:
	if body.name == "npc_shadowy_ghost":
		_ghot_turn_left()
		$"y-sorted/player_danilo/shock_sprite".queue_free()


func _on_shazam_body_entered(body: Node2D) -> void:
	print("play lightning sound here")
	SignalBus.dream_done.emit()
	WhiteTransitionFade.transition()
	SignalBus.next_scene.emit("res://scenes/game/act_3/scene_4/act_3_scene_4_part_2.tscn")
