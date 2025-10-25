extends Node2D

@onready var player_danilo: CharacterBody2D = $player_danilo
@onready var animated_sprite_2d_danilo: AnimatedSprite2D = $player_danilo/AnimatedSprite2D
@onready var collision_shape_danilo: CollisionShape2D = $player_danilo/CollisionShape2D
@onready var thunder_sfx: AudioStreamPlayer = $player_danilo/AudioStreamPlayer
@onready var dialogue_manager = DialogueManager   # assuming singleton / autoload

var wendy_instance

func _ready():
	# Instance Wendy from npc_wendy.tscn
	var wendy_scene = preload("res://scenes/characters/npc_wendy.tscn")
	wendy_instance = wendy_scene.instantiate()
	add_child(wendy_instance)
	wendy_instance.position = Vector2(120, 200) # adjust as needed in your map

	# Wendy faces right before any dialogue/cutscene
	_face_wendy_right()

	# Start Danilo cutscene intro
	await _intro_anim()

	# When animation is done, start the dialogue
	# Supply your dialogue resource, e.g. "res://dialogue/hospital.dialogue" or similar if using external resource
	DialogueManager.show_dialogue_balloon(null, "hospital") # or pass your dialogue resource if needed

func _face_wendy_right():
	var animated_sprite_2d_wendy: AnimatedSprite2D = wendy_instance.get_node("AnimatedSprite2D")
	if animated_sprite_2d_wendy:
		animated_sprite_2d_wendy.play("idle_right")

func _intro_anim() -> void:
	player_danilo.animation_locked = true
	player_danilo.can_move = false
	animated_sprite_2d_danilo.play("sleep_hospital")
	await get_tree().create_timer(10).timeout
	animated_sprite_2d_danilo.play("wake_hospital")
	await get_tree().create_timer(2).timeout
	animated_sprite_2d_danilo.play("idle_bed")  # Danilo stays in bed, awake
