extends Node2D

@onready var npc_mateo: CharacterBody2D = $"y-sorted-areas/npc_mateo"
@onready var animated_sprite_2d: AnimatedSprite2D = $"y-sorted-areas/npc_mateo/AnimatedSprite2D"
@onready var mateo_custom_animation_player: AnimationPlayer = $"y-sorted-areas/npc_mateo/AnimationPlayer"
@onready var danilo_animation_player: AnimationPlayer = $"y-sorted-areas/player_danilo/AnimationPlayer"
@onready var player_danilo: CharacterBody2D = $"y-sorted-areas/player_danilo"
@onready var npc_shadowy_chaser: CharacterBody2D = $"y-sorted-areas/npc_shadowy_chaser"

func _ready() -> void:
	FlashlightManager.set_current_scene("act_1", "scene_3")
	FlashlightManager.disable_flashlights()
	if BgmManager:
		BgmManager.stop_music();
		
		_danilo_cant_move()
		
		play_flashback()

func play_flashback() -> void:
	await get_tree().create_timer(2).timeout
	_shadow_figure_appear()
	
	await get_tree().create_timer(0.5).timeout
	_mateo_shocked()
	
	await get_tree().create_timer(0.5).timeout
	_mateo_run_down();
	_shadow_run_down();
	_danilo_worried()
	

func _danilo_cant_move() -> void:
	player_danilo.last_direction = Vector2.UP;
	player_danilo.can_move = false;
	

func _mateo_shocked() -> void:
	mateo_custom_animation_player.play("shock_in");

func _danilo_worried() -> void:
	danilo_animation_player.play("bothered_in");

func _mateo_run_down() -> void:
	npc_mateo.direction = Vector2.DOWN

func _shadow_run_down() -> void:
	npc_shadowy_chaser.direction = Vector2.DOWN

func _on_mateo_turn_body_entered(body: Node2D) -> void:
	if body.name == "npc_mateo":
		_mateo_run_left();


func _mateo_run_left() -> void:
	npc_mateo.direction = Vector2.LEFT
	await get_tree().create_timer(0.1).timeout
	player_danilo.last_direction = Vector2.LEFT

func _shadow_turn_left() -> void:
	npc_shadowy_chaser.direction = Vector2.LEFT

func _on_mate_stop_body_entered(body: Node2D) -> void:
	if body.name == "npc_mateo":
		npc_mateo.direction = Vector2.ZERO;

func _shadow_figure_appear() -> void:
	npc_shadowy_chaser.visible = true;

func _on_shadow_turn_body_entered(body: Node2D) -> void:
	if body.name == "npc_shadowy_chaser":
		_shadow_turn_left()

func _on_shadow_stop_body_entered(body: Node2D) -> void:
	if body.name == "npc_shadowy_chaser":
		npc_shadowy_chaser.direction = Vector2.ZERO
		SignalBus.habulan_done.emit();
