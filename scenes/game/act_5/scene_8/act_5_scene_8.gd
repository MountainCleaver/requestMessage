extends Node2D

const A_5S_8 = preload("uid://cdmrub6bunwtt")

var act_4_scene_1_choice : String = ""
@onready var player_danilo: CharacterBody2D = $"locations/chapel_interior/y-sorted/player_danilo"
@onready var animated_sprite_2d: AnimatedSprite2D = $"locations/chapel_interior/y-sorted/player_danilo/AnimatedSprite2D"
@onready var collision_shape_2d: CollisionShape2D = $"locations/chapel_interior/y-sorted/player_danilo/CollisionShape2D"
@onready var npc_shadowy_ghost: CharacterBody2D = $"locations/chapel_interior/y-sorted/npc_shadowy_ghost"
@onready var npc_whitey_ghost: CharacterBody2D = $"locations/chapel_interior/y-sorted/npc_whitey_ghost"

@onready var reading_position: Marker2D = $"locations/chapel_interior/y-sorted/markers/reading_position"
@onready var mateo_appear_position: Marker2D = $"locations/chapel_interior/y-sorted/markers/mateo_appear_position"
@onready var danilo_talking_position: Marker2D = $"locations/chapel_interior/y-sorted/markers/danilo_talking_position"
@onready var mateo_stop_position: Marker2D = $"locations/chapel_interior/y-sorted/markers/mateo_stop_position"

@onready var mateo_stap: Area2D = $"locations/chapel_interior/y-sorted/mateo_stap"
@onready var candle: Node2D = $locations/chapel_interior/map/candle
@onready var tip_shocked: Sprite2D = $"locations/chapel_interior/y-sorted/player_danilo/tip_shocked"
@onready var distortiooooooooon: CanvasLayer = $DISTORTIOOOOOOOOON
@onready var color_rect: ColorRect = $DISTORTIOOOOOOOOON/ColorRect
@onready var big_point_light_2d: PointLight2D = $locations/chapel_interior/map/candle/big_candle/PointLight2D

signal ghost_appears(choice: String)

func _ready() -> void:
	
	ghost_appears.connect(_ghost_appear)
	
	act_4_scene_1_choice = SaveManager.get_moral_choice("act_4_scene_1")
	print(act_4_scene_1_choice)
	_set_danilo_altar()
	#play_dialog(act_4_scene_1_choice)
	play_dialog("restless")

func _set_danilo_altar()-> void: # danilo sitting on the altar, reading the diary
	player_danilo.global_position = reading_position.global_position
	player_danilo.animation_locked = true
	player_danilo.force_cannot_move = true
	collision_shape_2d.disabled = true
	player_danilo.z_index = 99
	animated_sprite_2d.play("read_notebook")

func _set_danilo_get_down_from_alter() -> void:
	#TransitionFade.transition()
	#await SignalBus.on_transition_finished
	
	player_danilo.global_position = danilo_talking_position.global_position
	animated_sprite_2d.play("idle_down")
	tip_shocked.visible = false

func play_dialog(choice: String) ->void:
	if choice == "restless":
		DialogueManager.show_dialogue_balloon(A_5S_8, "condition_worsened")
	elif choice == "relief":
		DialogueManager.show_dialogue_balloon(A_5S_8, "condition_stabilized")

func big_candle()->void:
	var tween = create_tween()
	tween.tween_property(big_point_light_2d, "texture_scale", 9.0, 1.0)

func _candle_dimmer()->void:
	var candles: Array[PointLight2D] = []

	for node in candle.get_children():
		var light2D := node.get_node_or_null("PointLight2D")
		if light2D:
			candles.append(light2D)
	
	for light in candles:
		var tween := create_tween()
		tween.tween_property(light, "energy", 0.6, 1.5)
		tween.tween_property(light, "texture_scale", 4.5, 1.5)

func _candle_dim() -> void:
	var candles: Array[PointLight2D] = []

	for node in candle.get_children():
		var light2D := node.get_node_or_null("PointLight2D")
		if light2D:
			candles.append(light2D)
	
	for light in candles:
		var tween := create_tween()
		tween.tween_property(light, "energy", 1.0, 1.5)
		tween.tween_property(light, "texture_scale", 4.5, 1.5)
	


func _ghost_appear(choice: String)->void: # after some dialogues, ghost appears, depending on the choice is the one who will appear here
	# ghost will out of from the shadows then stop in the middle of the chapel
	tip_shocked.visible = true

	if choice == "restless":
		npc_shadowy_ghost.visible = true
		npc_shadowy_ghost.global_position = mateo_appear_position.global_position
		npc_shadowy_ghost.last_vertical = "up"
		var tween = create_tween()
		tween.tween_property(npc_shadowy_ghost, "global_position", mateo_stop_position.global_position, 2.0)
	elif choice == "relief":
		big_candle()
		npc_whitey_ghost.visible = true
		npc_whitey_ghost.global_position = mateo_appear_position.global_position
		npc_whitey_ghost.last_vertical = "up"
		var tween = create_tween()
		tween.tween_property(npc_whitey_ghost, "global_position", mateo_stop_position.global_position, 2.0)
		
	
	await get_tree().create_timer(2.0).timeout
	_set_danilo_get_down_from_alter()
	
	if choice == "restless":
		DialogueManager.show_dialogue_balloon(A_5S_8, "resltess_ghost_appeared")
	elif choice == "relief":
		DialogueManager.show_dialogue_balloon(A_5S_8, "relief_mateo_appeared")

func mateo_turn(choice: String)->void:
	if choice == "relief":
		npc_whitey_ghost.last_vertical = "down"
		DialogueManager.show_dialogue_balloon(A_5S_8, "relief_mateo_turned")
	elif choice == "restless":
		npc_shadowy_ghost.last_vertical = "down"

func mateo_walk_down(choice: String) -> void:
	if choice == "relief":
		npc_whitey_ghost.last_vertical = "down"
		var tween = create_tween()
		tween.tween_property(npc_whitey_ghost, "global_position", mateo_appear_position.global_position, 3.0)
	elif choice == "restless":
		var tween = create_tween()
		tween.tween_property(npc_shadowy_ghost, "global_position", mateo_appear_position.global_position, 3.0)
	
	_go_outside()
func show_distortion(duration: float = 1.5, target_opacity: float = 1.0) -> void:
	# Ensure the distortion layer is visible
	distortiooooooooon.visible = true

	# Start fully transparent
	color_rect.modulate.a = 0.0

	# Tween to full opacity (or a custom target)
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", target_opacity, duration)

func _go_outside()->void:
	SignalBus.next_scene.emit("res://scenes/game/act_5/scene_8/act_5_scene_8_outside_scene.tscn")
