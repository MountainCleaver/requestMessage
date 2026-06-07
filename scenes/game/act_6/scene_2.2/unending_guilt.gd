extends Node2D
var A_6S_2_2: Resource
@onready var player_danilo: CharacterBody2D = $hospital/player_danilo
@onready var animated_sprite_2d_danilo: AnimatedSprite2D = $hospital/player_danilo/AnimatedSprite2D
@onready var collision_shape_danilo: CollisionShape2D = $hospital/player_danilo/CollisionShape2D
@onready var wendy: CharacterBody2D = $hospital/wendy
@onready var animated_sprite_2d_wendy: AnimatedSprite2D = $hospital/wendy/AnimatedSprite2D

var blink_overlay: ColorRect
var is_blinking := false
var blink_timer := 0.0
var blink_interval := 3.0

var glitch_overlay: ColorRect
var is_glitching := false
var glitch_timer := 0.0
var glitch_interval := 2.5

func _ready():
	start_animation() 
	FlashlightManager.set_current_scene("act_6", "scene_2")
	FlashlightManager.disable_flashlights()
	_load_dialogue()
	create_blink_overlay()
	create_glitch_overlay()
	await get_tree().process_frame
	await _show_intro_narration()


func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_6/scene_2.2/a6s2.2_en.dialogue"
	else:
		path = "res://dialogues/act_6/scene_2.2/a6s2.2.dialogue"
	
	A_6S_2_2 = load(path)
	
func _show_intro_narration() -> void:
	var lines = [
		"The villagers rush Danilo to the local hospital.",
        "Few days later, he awakens in a dimly lit room, Wendy at his side."
	]
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	await start_animation()
	await start_cutscene()

func create_blink_overlay():
	blink_overlay = ColorRect.new()
	blink_overlay.name = "BlinkOverlay"
	blink_overlay.color = Color(0, 0, 0, 0)
	blink_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	canvas_layer.add_child(blink_overlay)
	blink_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func create_glitch_overlay():
	glitch_overlay = ColorRect.new()
	glitch_overlay.name = "GlitchOverlay"
	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	glitch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 99
	add_child(canvas_layer)
	canvas_layer.add_child(glitch_overlay)
	glitch_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta):
	if not is_blinking:
		blink_timer += delta
		if blink_timer >= blink_interval:
			blink_timer = 0.0
			trigger_eye_blink()
			blink_interval = randf_range(2.5, 4.0)
	
	if not is_glitching:
		glitch_timer += delta
		if glitch_timer >= glitch_interval:
			glitch_timer = 0.0
			trigger_glitch()
			glitch_interval = randf_range(4.0, 5.5)

func trigger_eye_blink():
	if is_blinking:
		return
	
	is_blinking = true
	await blink_animation()

func blink_animation():
	var tween = create_tween()
	tween.tween_property(blink_overlay, "color:a", 1.0, 0.15).set_ease(Tween.EASE_IN)
	await tween.finished

	await get_tree().create_timer(0.1).timeout

	tween = create_tween()
	tween.tween_property(blink_overlay, "color:a", 0.0, 0.2).set_ease(Tween.EASE_OUT)
	await tween.finished

	is_blinking = false

func trigger_glitch():
	if is_glitching:
		return
	
	is_glitching = true
	var glitch_type = randi() % 3

	match glitch_type:
		0:
			await glitch_color_flash()
		1:
			await glitch_flicker()
		2:
			await glitch_static()

	is_glitching = false

func glitch_color_flash():
	for i in range(3):
		glitch_overlay.color = Color(1.0, 0.7, 0.7, randf_range(0.15, 0.25))
		await get_tree().create_timer(0.05).timeout

		glitch_overlay.color = Color(0.7, 0.7, 1.0, randf_range(0.15, 0.25))
		await get_tree().create_timer(0.05).timeout

	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

func glitch_flicker():
	for i in range(5):
		glitch_overlay.color = Color(
			randf_range(0.8, 1.2),
			randf_range(0.8, 1.2),
			randf_range(0.8, 1.2),
			randf_range(0.1, 0.2)
		)
		await get_tree().create_timer(0.04).timeout

	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

func glitch_static():
	for i in range(4):
		glitch_overlay.color = Color(
			randf_range(0.7, 1.3),
			randf_range(0.7, 1.3),
			randf_range(0.7, 1.3),
			randf_range(0.12, 0.2)
		)
		await get_tree().create_timer(0.06).timeout

	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

func start_animation() -> void:
	player_danilo.animation_locked = true
	player_danilo.can_move = false
	player_danilo.force_cannot_move = true
	collision_shape_danilo.disabled = true

	animated_sprite_2d_danilo.play("sleep_hospital")
	animated_sprite_2d_wendy.play("idle_right")
	await get_tree().create_timer(2.0).timeout

	animated_sprite_2d_danilo.play("wake_hospital")
	await get_tree().create_timer(2.5).timeout

	animated_sprite_2d_danilo.play("idle_bed")


func start_cutscene() -> void:
	var balloon = DialogueManager.show_dialogue_balloon(
		A_6S_2_2,
		"start",
		[self]
	)
	if balloon:
		balloon.tree_exited.connect(_on_dialogue_done)

func _on_dialogue_done():
	await _danilo_despair_animation()
	await _show_narration_scene()

func _danilo_despair_animation() -> void:
	trigger_eye_blink()
	trigger_glitch()
	await get_tree().create_timer(0.5).timeout

	trigger_eye_blink()
	trigger_glitch()
	await get_tree().create_timer(0.8).timeout

	trigger_eye_blink()
	trigger_glitch()
	await get_tree().create_timer(0.6).timeout

	animated_sprite_2d_danilo.play("close_eyes")
	await get_tree().create_timer(1.0).timeout

	await final_glitch_sequence()
	await slow_eye_close()
	await get_tree().create_timer(0.5).timeout

func final_glitch_sequence():
	for i in range(8):
		glitch_overlay.color = Color(
			randf_range(0.6, 1.4),
			randf_range(0.6, 1.4),
			randf_range(0.6, 1.4),
			randf_range(0.2, 0.35)
		)
		await get_tree().create_timer(0.07).timeout

	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

func slow_eye_close() -> void:
	var tween = create_tween()
	tween.tween_property(blink_overlay, "color:a", 1.0, 2.0).set_ease(Tween.EASE_IN)
	await tween.finished

func _show_narration_scene() -> void:
	SignalBus.on_transition_finished.connect(_on_transition_finished, CONNECT_ONE_SHOT)
	TransitionFade.transition()

func _on_transition_finished():
	SaveManager.track_ending(Session.user_ID, get_tree().current_scene.scene_file_path)
	get_tree().change_scene_to_file("res://scenes/game/act_6/scene_2.2/bad_ending.tscn")
		
 