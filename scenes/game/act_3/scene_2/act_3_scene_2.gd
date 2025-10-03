extends Node2D

@onready var player_danilo: CharacterBody2D = $"danilo_hometown_house/y-sorted/player_danilo"
@onready var animated_sprite_2d: AnimatedSprite2D = $"danilo_hometown_house/y-sorted/player_danilo/AnimatedSprite2D"
const A_3S_2 = preload("uid://vpb3fshkkblr")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_danilo.animation_locked = true;
	player_danilo.force_cannot_move = true;
	animated_sprite_2d.play("sitting")
	Hud.phone_intro()
	DialogueManager.show_dialogue_balloon(A_3S_2, "start")
	
