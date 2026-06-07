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

	var label: DialogueLabel = $end/TextureRect/DialogueLabel2
	label.show()

	var line: DialogueLine = await A_5S_5.get_next_dialogue_line("mateo_calling_for_help")

	while line:
		label.dialogue_line = line 
		label.type_out() 

		await label.finished_typing

		var advanced := false
		while not advanced:
			await get_tree().process_frame
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_just_pressed("dialog_next"):
				advanced = true

		if not line.next_id or line.next_id == "END" or line.next_id == "":
			break
		line = await A_5S_5.get_next_dialogue_line(line.next_id)


func act_5_scene_5_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_5"
	SaveManager.save_game()
	SignalBus.act_num_scene_num_done.emit(
		"act_5", "scene_5", "res://scenes/game/act_5/scene_6/act_5_scene_6.tscn"
	)
		
 