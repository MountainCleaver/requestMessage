extends Node2D

# === Preloads ===
const A_5S_4 = preload("uid://by7wjj33esup2")

# === References: Characters ===
@onready var mateo: CharacterBody2D = $TileMapLayer/mateo
@onready var npc_danilo: CharacterBody2D = $TileMapLayer/npc_danilo
@onready var wendy: CharacterBody2D = $TileMapLayer/wendy
@onready var npc_gino: CharacterBody2D = $TileMapLayer/npc_gino_with_stick

# === References: Hiding Spots ===
@onready var danilo_hiding_spot: Marker2D = $spawn_points/daniloHidingSpot
@onready var mateo_hiding_spot: Marker2D = $spawn_points/mateoHidingSpot
@onready var wendy_hiding_spot: Marker2D = $spawn_points/wendyHidingSpot

# === References: Animations ===
@onready var mateo_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/mateo/AnimatedSprite2D
@onready var danilo_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/npc_danilo/AnimatedSprite2D
@onready var wendy_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/wendy/AnimatedSprite2D
@onready var gino_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/npc_gino_with_stick/AnimatedSprite2D

@onready var danilo_anim: AnimationPlayer = $TileMapLayer/npc_danilo/Sprite2D/danilo_anim
@onready var mateo_anim: AnimationPlayer = $TileMapLayer/mateo/AnimationPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var camera_2d: Camera2D = $Camera2D

var chase_camera: bool = false
@export var camera_follow_speed: float = 8.0



# === Lifecycle ===
func _ready() -> void:
	npc_gino.visible = false
	wendy_animated_sprite_2d.play("idle_down")
	danilo_animated_sprite_2d.play("idle_up")
	mateo_animated_sprite_2d.play("idle_up")

	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue_balloon(A_5S_4, "start")

func _physics_process(delta: float) -> void:
	if chase_camera:
		camera_2d.position = camera_2d.position.lerp(mateo.position, delta * camera_follow_speed)
		# Using lerp() keeps movement smooth without frame snapping.

# === Sequence: Start Hiding ===
func _start_hiding() -> void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished

	mateo.global_position = mateo_hiding_spot.global_position
	npc_danilo.global_position = danilo_hiding_spot.global_position
	wendy.global_position = wendy_hiding_spot.global_position

	mateo_animated_sprite_2d.play("idle_down")
	danilo_animated_sprite_2d.play("idle_up")
	wendy_animated_sprite_2d.play("idle_left")

	DialogueManager.show_dialogue_balloon(A_5S_4, "danilo")

func _mang_gino_appears() -> void:
	animation_player.play("camera_shake")
	await animation_player.animation_finished
	npc_gino.visible = true
	mateo_anim.play("shock_in")
	animation_player.play("tension")

	await get_tree().create_timer(0.5).timeout
	_chase_start()

func _chase_start() -> void:
	mateo.direction = Vector2.DOWN
	npc_gino.direction = Vector2.DOWN
	
	await get_tree().create_timer(0.3).timeout
	danilo_anim.play("danilo_questions")
	
	await get_tree().create_timer(0.4).timeout
	mateo.direction = Vector2.LEFT

	await get_tree().create_timer(0.25).timeout
	danilo_animated_sprite_2d.play("idle_left")
	npc_gino.direction = Vector2.LEFT

	await get_tree().create_timer(0.5).timeout
	_aim_camera_to_mateo()

func _aim_camera_to_mateo() -> void:
	var tween = create_tween()
	tween.tween_property(camera_2d, "position", mateo.position, 1.0)
	await tween.finished
	chase_camera = true

# === Act Done ===
func act_5_scene_4_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_5"
	SignalBus.act_num_scene_num_done.emit("act_5", "scene_4", "res://scenes/game/act_5/scene_5/act_5_scene_5.tscn")

func _on_scene_end_body_entered(body: Node2D) -> void:
	if body.name == "mateo":
		await get_tree().create_timer(1.0).timeout
		act_5_scene_4_done()
		
