extends Node2D

@onready var mateo: CharacterBody2D = $mateo
@onready var animated_sprite_2d: AnimatedSprite2D = $mateo/AnimatedSprite2D
@onready var end: CanvasLayer = $end
@onready var endimation: AnimationPlayer = $end/endimation
@onready var atmosphere: CanvasModulate = $act_5_scene_5/atmosphere

@onready var sfx_crying: AudioStreamPlayer = $SFX_CRYING
@onready var sfx_heart: AudioStreamPlayer = $SFX_heartbeat
@onready var bgm_out: AudioStreamPlayer = $BGM_OUT
@onready var bgm_cliff: AudioStreamPlayer = $BGM_cliff


var A_5S_5: Resource

func _ready() -> void:
	bgm_out.play()
	_load_dialogue()
	end.visible = false
	
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_5/scene_5/a5s5_en.dialogue"
	else:
		path = "res://dialogues/act_5/scene_5/a5s5.dialogue"
	
	A_5S_5 = load(path)

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
	bgm_out.stop()
	sfx_crying.play()
	sfx_heart.play()
	bgm_cliff.play()
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
