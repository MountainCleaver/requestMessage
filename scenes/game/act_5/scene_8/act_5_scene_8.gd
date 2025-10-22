extends Node2D

const A_5S_8 = preload("uid://cdmrub6bunwtt")

var act_4_scene_1_choice : String = ""
@onready var reading_position: Marker2D = $reading_position
@onready var player_danilo: CharacterBody2D = $"locations/chapel_interior/y-sorted/player_danilo"
@onready var animated_sprite_2d: AnimatedSprite2D = $"locations/chapel_interior/y-sorted/player_danilo/AnimatedSprite2D"
@onready var collision_shape_2d: CollisionShape2D = $"locations/chapel_interior/y-sorted/player_danilo/CollisionShape2D"

func _ready() -> void:
	act_4_scene_1_choice = SaveManager.get_moral_choice("act_4_scene_1")
	_set_danilo_altar()
	

func _set_danilo_altar()-> void:
	player_danilo.global_position = reading_position.global_position
	player_danilo.animation_locked = true
	player_danilo.force_cannot_move = true
	collision_shape_2d.disabled = true
	player_danilo.z_index = 99
	animated_sprite_2d.play("read_notebook")
