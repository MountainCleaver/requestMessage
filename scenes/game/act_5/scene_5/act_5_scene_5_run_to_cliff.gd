extends Node2D

@onready var mateo: CharacterBody2D = $mateo
@onready var animated_sprite_2d: AnimatedSprite2D = $mateo/AnimatedSprite2D
@onready var end: CanvasLayer = $end
@onready var endimation: AnimationPlayer = $end/endimation
@onready var atmosphere: CanvasModulate = $act_5_scene_5/atmosphere

const A_5S_5 = preload("uid://chxxs3lhxttid")

func _ready() -> void:
	end.visible = false

func _mateo_run_down() -> void:
	mateo.direction = Vector2.DOWN
	# animated_sprite_2d.play("walk_down")

func _mateo_run_right() -> void:
	mateo.direction = Vector2.RIGHT
	# animated_sprite_2d.play("walk_right")

func _mateo_run_left() -> void:
	mateo.direction = Vector2.LEFT
	# animated_sprite_2d.play("walk_left")

func _mateo_run_up() -> void:
	mateo.direction = Vector2.UP
	# animated_sprite_2d.play("walk_up")


func _show_end() -> void:
	end.visible = true
	endimation.play("end")
	mateo.queue_free()
	DialogueManager.show_dialogue_balloon(A_5S_5, "mateo_calling_for_help")

func act_5_scene_5_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_6"
	SignalBus.act_num_scene_num_done.emit(
		"act_5", "scene_5", "res://scenes/game/act_5/scene_6/act_5_scene_6.tscn"
	)
