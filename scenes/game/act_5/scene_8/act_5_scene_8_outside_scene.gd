extends Node2D

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var ghost_location: Marker2D = $"locations/cliff/y-sorted/markers/ghost_location"

@onready var npc_whitey_ghost: CharacterBody2D = $"locations/cliff/y-sorted/npc_whitey_ghost"
@onready var npc_shadowy_ghost: CharacterBody2D = $"locations/cliff/y-sorted/npc_shadowy_ghost"
@onready var player_danilo: CharacterBody2D = $"locations/cliff/y-sorted/player_danilo"

@onready var distortion: CanvasLayer = $distortion
@onready var color_rect: ColorRect = $distortion/ColorRect

@onready var whitey_initial_location: Marker2D = $"locations/cliff/y-sorted/markers/whitey_initial_location"

var act_4_scene_1_choice : String
const A_5S_8 = preload("uid://cdmrub6bunwtt")

func _ready() -> void:
	
	player_danilo.force_cannot_move = true
	player_danilo.last_direction = Vector2.LEFT
	act_4_scene_1_choice = SaveManager.get_moral_choice("act_4_scene_1")
	print(act_4_scene_1_choice)
	
	if act_4_scene_1_choice == "restless":
		distortion.visible = true

	_set_ghost_position("restless")

func _set_ghost_position(choice: String)->void:
	if choice == "restless":
		canvas_modulate.color = Color("4e2564")
		npc_shadowy_ghost.global_position = ghost_location.global_position
	elif choice == "relief":
		npc_whitey_ghost.z_index = 5;
		npc_whitey_ghost.direction = Vector2.LEFT
		npc_whitey_ghost.global_position =  whitey_initial_location.global_position
		var coll = npc_shadowy_ghost.get_node_or_null("CollisionShape2D")
		if coll:
			coll.disabled = true
		canvas_modulate.color = Color("2b356c")
		
		var tween = create_tween()
		tween.tween_property(npc_whitey_ghost, "global_position", ghost_location.global_position, 2.0)
		await tween.finished
		coll.disabled = false
		
		#npc_whitey_ghost.last_vertical = "down"
		#npc_whitey_ghost.direction = Vector2.ZERO
		
	if choice == "restless":
		await get_tree().create_timer(2.0).timeout
	
	_ghost_right(choice)


func _ghost_right(choice: String) -> void:
	
	if choice == "restless":
		npc_shadowy_ghost.direction = Vector2.RIGHT
		DialogueManager.show_dialogue_balloon(A_5S_8, "restless_cliff")
		
	elif choice == "relief":
		npc_whitey_ghost.direction = Vector2.RIGHT
		DialogueManager.show_dialogue_balloon(A_5S_8, "relief_cliff")

func _ghost_down(choice: String) -> void:
	
	if choice == "restless":
		npc_shadowy_ghost.direction = Vector2.ZERO
	elif choice == "relief":
		npc_whitey_ghost.direction = Vector2.ZERO

func _ghost_left(choice: String) -> void:
	
	if choice == "restless":
		npc_shadowy_ghost.direction = Vector2.LEFT
	elif choice == "relief":
		npc_whitey_ghost.direction = Vector2.LEFT

func _ghost_vanish(choice: String) -> void:
	
	if choice == "restless":
		var tween = create_tween()
		tween.tween_property(color_rect, "modulate:a", 0.0, 2.0)
		tween.tween_property(npc_shadowy_ghost, "modulate:a", 0.0, 2.0)
		#await tween.finished
	elif choice == "relief":
		var tween = create_tween()
		tween.tween_property(npc_whitey_ghost, "modulate:a", 0.3, 5.0)

func whitey_vanish_full() -> void:
	var tween = create_tween()
	tween.tween_property(npc_whitey_ghost, "modulate:a", 0.0, 1.0)
