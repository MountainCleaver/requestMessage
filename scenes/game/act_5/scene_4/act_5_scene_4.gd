extends Node2D

# === Preloads ===
const A_5S_4 = preload("uid://by7wjj33esup2")

# === References: Characters ===
@onready var player_mateo: CharacterBody2D = $TileMapLayer/player_mateo
@onready var npc_danilo: CharacterBody2D = $TileMapLayer/npc_danilo
@onready var wendy: CharacterBody2D = $TileMapLayer/wendy

# === References: Hiding Spots ===
@onready var danilo_hiding_spot: Marker2D = $daniloHidingSpot
@onready var mateo_hiding_spot: Marker2D = $mateoHidingSpot
@onready var wendy_hiding_spot: Marker2D = $wendyHidingSpot

# === References: Animations ===
@onready var mateo_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/player_mateo/AnimatedSprite2D
@onready var danilo_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/npc_danilo/AnimatedSprite2D
@onready var wendy_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/wendy/AnimatedSprite2D


# === Lifecycle ===
func _ready() -> void:
	player_mateo.force_cannot_move = true
	
	wendy_animated_sprite_2d.play("idle_down")
	danilo_animated_sprite_2d.play("idle_up")
	player_mateo.last_direction = Vector2.UP
	
	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue_balloon(A_5S_4, "start")


# === Sequence: Start Hiding ===
func _start_hiding() -> void:
	# Fade to black before hiding
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	
	# Relocate characters
	player_mateo.global_position = mateo_hiding_spot.global_position
	npc_danilo.global_position = danilo_hiding_spot.global_position
	wendy.global_position = wendy_hiding_spot.global_position
	
	# Fix character directions
	player_mateo.last_direction = Vector2.DOWN
	danilo_animated_sprite_2d.play("idle_up")
	wendy_animated_sprite_2d.play("idle_left")
	
	# Play dialogues
	DialogueManager.show_dialogue_balloon(A_5S_4, "danilo")

# === Act Done ===
func act_5_scene_4_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_5"
	SignalBus.act_num_scene_num_done.emit("act_5", "scene_4", "res://scenes/game/act_5/scene_5/act_5_scene_5.tscn")
