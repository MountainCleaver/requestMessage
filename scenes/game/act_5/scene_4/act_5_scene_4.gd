extends Node2D

# === Preloads ===
var A_5S_4: Resource

# === Sounds ===
@onready var sfx_laughing: AudioStreamPlayer = $SFX_LAUGHING
@onready var sfx_rustle: AudioStreamPlayer = $SFX_RUSTLE
@onready var sfx_shock: AudioStreamPlayer = $SFX_SHOCK
@onready var sfx_clock: AudioStreamPlayer = $SFX_CLOCK
@onready var bgm_laruan: AudioStreamPlayer = $BGM_LARUAN
@onready var bgm_tensed: AudioStreamPlayer = $BGM_TENSED



# === References: Characters ===
@onready var mateo: CharacterBody2D = $TileMapLayer/mateo
@onready var npc_danilo: CharacterBody2D = $TileMapLayer/npc_danilo
@onready var wendy: CharacterBody2D = $TileMapLayer/wendy
@onready var npc_gino: CharacterBody2D = $TileMapLayer/npc_gino_with_stick

# === References: Hiding Spots ===
@onready var mateo_hiding_spot: Marker2D = $spawn_points/mateoHidingSpot
@onready var danilo_hiding_spot: Marker2D = $spawn_points/daniloHidingSpot
@onready var wendy_hiding_spot: Marker2D = $spawn_points/wendyHidingSpot

# === References: Animations ===
@onready var mateo_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/mateo/AnimatedSprite2D
@onready var danilo_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/npc_danilo/AnimatedSprite2D
@onready var wendy_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/wendy/AnimatedSprite2D
@onready var gino_animated_sprite_2d: AnimatedSprite2D = $TileMapLayer/npc_gino_with_stick/AnimatedSprite2D

@onready var mateo_anim: AnimationPlayer = $TileMapLayer/mateo/AnimationPlayer
@onready var danilo_anim: AnimationPlayer = $TileMapLayer/npc_danilo/Sprite2D/danilo_anim
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# === References: Camera ===
@onready var camera_2d: Camera2D = $Camera2D
@export var camera_follow_speed: float = 8.0
var chase_camera: bool = false


# === Lifecycle ===
func _ready() -> void:
	npc_gino.visible = false
	bgm_laruan.play()
	sfx_laughing.play()
	
	_load_dialogue()
	# Set initial character animations
	wendy_animated_sprite_2d.play("idle_down")
	danilo_animated_sprite_2d.play("idle_up")
	mateo_animated_sprite_2d.play("idle_up")

	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue_balloon(A_5S_4, "start")
	
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_5/scene_4/a5s4_en.dialogue"
	else:
		path = "res://dialogues/act_5/scene_4/a5s4.dialogue"
	
	A_5S_4 = load(path)
	

func _physics_process(delta: float) -> void:
	if chase_camera:
		camera_2d.position = camera_2d.position.lerp(mateo.position, delta * camera_follow_speed)
		# Smooth camera tracking without sudden jumps


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


# === Sequence: Gino Appears and Chase Starts ===
func _mang_gino_appears() -> void:
	bgm_laruan.stop()
	sfx_laughing.stop()
	sfx_shock.play()
	
	animation_player.play("camera_shake")
	await animation_player.animation_finished

	npc_gino.visible = true
	mateo_anim.play("shock_in")
	animation_player.play("tension")

	await get_tree().create_timer(0.5).timeout
	_chase_start()


func _chase_start() -> void:
	bgm_tensed.play()
	sfx_clock.play()
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


# === Camera Control ===
func _aim_camera_to_mateo() -> void:
	var tween = create_tween()
	tween.tween_property(camera_2d, "position", mateo.position, 1.0)
	await tween.finished
	chase_camera = true


# === Scene Completion ===
func act_5_scene_4_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_4"
	SaveManager.save_game()
	SignalBus.act_num_scene_num_done.emit(
		"act_5",
		"scene_4",
		"res://scenes/game/act_5/scene_5/act_5_scene_5_mini_game_start.tscn"
	)


func _on_scene_end_body_entered(body: Node2D) -> void:
	if body.name == "mateo":
		await get_tree().create_timer(1.0).timeout
		act_5_scene_4_done()
