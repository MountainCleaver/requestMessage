extends Node2D

@onready var narration_text: RichTextLabel = $CanvasLayer/Control/Panel/TextureRect/RichTextLabel
@onready var skip_button: Button = $CanvasLayer/Control/Panel/TextureRect/Button
@onready var play_pause_button: Button = $CanvasLayer/Control/Panel/TextureRect/play_pause_button
@onready var bgm: AudioStreamPlayer = $BGMBad
@onready var texture_rect: TextureRect = $CanvasLayer/Control/Panel/TextureRect

var glitch_overlay: ColorRect

var pause_icon = preload("res://assets/character_sprites/pause.png")  
var play_icon = preload("res://assets/character_sprites/play.png")    

var story_lines = [
	"[center]Danilo's hands trembled as he held onto the diary, refusing to let it go. Every time he closed his eyes, Mateo's voice echoed in his head, calling, accusing.[/center]",
	"",
	"",
	"[center]That night, as Wendy slept on the chair beside him, Danilo stared blankly at the ceiling.[/center]",
	"",
	"",
	"[center]Though his body survived, his spirit remained trapped, forever haunted by guilt, unable to escape Mateo's shadow.[/center]"
]

var current_line_index := 0
var scroll_speed := 22.0
var is_scrolling := true
var initial_y_position := 0.0
var has_shown_end := false
var screen_height := 0.0

var glitch_timer := 0.0
var glitch_interval := 4.0
var is_glitching := false
var glitch_active := true

func _ready():
	screen_height = get_viewport().get_visible_rect().size.y
	
	narration_text.add_theme_constant_override("line_separation", 15) 
	
	var style = StyleBoxFlat.new()
	style.content_margin_left = 200
	style.content_margin_right = 200
	style.content_margin_top = 80
	style.content_margin_bottom = 80
	style.bg_color = Color(0, 0, 0, 0) 
	narration_text.add_theme_stylebox_override("normal", style)
	
	narration_text.scroll_active = false
	narration_text.scroll_following = false
	
	skip_button.visible = false
	play_pause_button.visible = true
	
	play_pause_button.icon = pause_icon
	
	initial_y_position = narration_text.position.y
	
	narration_text.text = "\n".join(story_lines)
	
	skip_button.pressed.connect(_on_back_button_pressed)
	play_pause_button.pressed.connect(_on_play_pause_button_pressed)
	
	create_glitch_overlay()
	
	create_vignette()
	
	if bgm.stream != null:
		bgm.play()
	
	start_glitch_effects()
	
	await get_tree().create_timer(1.5).timeout
	start_scrolling()

func create_glitch_overlay():
	glitch_overlay = ColorRect.new()
	glitch_overlay.name = "GlitchOverlay"
	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)  
	glitch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	texture_rect.add_child(glitch_overlay)
	texture_rect.move_child(glitch_overlay, 0) 
	
	glitch_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func create_vignette():
	var vignette = TextureRect.new()
	vignette.name = "Vignette"
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient_texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	
	gradient.set_color(0, Color(0, 0, 0, 0.0))   
	gradient.set_color(1, Color(0, 0, 0, 0.9))  
	
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.fill_from = Vector2(0.5, 0.5)  
	gradient_texture.fill_to = Vector2(1.0, 1.0)    
	
	vignette.texture = gradient_texture
	
	$CanvasLayer/Control.add_child(vignette)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta):
	if is_scrolling and not has_shown_end:
		narration_text.position.y -= scroll_speed * delta
		
		var target_lines_bottom = narration_text.position.y + narration_text.size.y
		
		if target_lines_bottom < screen_height * 0.2: 
			show_the_end()
	
	if glitch_active:
		glitch_timer += delta
		if glitch_timer >= glitch_interval:
			glitch_timer = 0.0
			trigger_background_glitch()

func start_glitch_effects():
	glitch_interval = randf_range(2.5, 3.5)

func trigger_background_glitch():
	if is_glitching or has_shown_end:
		return
	
	is_glitching = true
	
	var glitch_type = randi() % 3
	
	match glitch_type:
		0:
			await glitch_rgb_background()
		1:
			await glitch_static_background()
		2:
			await glitch_scanlines_background()
	
	is_glitching = false
	glitch_interval = randf_range(1.5, 2.5)

func glitch_rgb_background() -> void:
	for i in range(4):
		glitch_overlay.color = Color(
			randf_range(0.7, 1.3),
			randf_range(0.4, 0.9),
			randf_range(0.7, 1.3),
			randf_range(0.2, 0.55)  
		)
		await get_tree().create_timer(0.06).timeout
	
	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

func glitch_static_background() -> void:
	for i in range(6):
		glitch_overlay.color = Color(
			randf_range(0.5, 1.4),
			randf_range(0.5, 1.4),
			randf_range(0.5, 1.4),
			randf_range(0.25, 0.4)  
		)
		await get_tree().create_timer(0.04).timeout
	
	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

func glitch_scanlines_background() -> void:
	for i in range(5):
		glitch_overlay.color = Color(
			randf_range(0.6, 1.2),
			randf_range(0.6, 1.2),
			randf_range(0.6, 1.2),
			randf_range(0.15, 0.3)  
		)
		await get_tree().create_timer(0.05).timeout
	
	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

func show_the_end():
	has_shown_end = true
	glitch_active = false 
	
	play_pause_button.visible = false
	
	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	
	var end_label = Label.new()
	end_label.name = "TheEndLabel"
	end_label.text = "THE END"
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var battery_park_font = load("res://assets/fonts/BatteryPark.ttf") 
	if battery_park_font:
		end_label.add_theme_font_override("font", battery_park_font)
		end_label.add_theme_font_size_override("font_size", 64) 
	else:
		print("BatteryPark font not found! Using default font.")
		end_label.add_theme_font_size_override("font_size", 72)
	
	end_label.add_theme_color_override("font_color", Color(1.0, 0.293, 0.295, 1.0))
	
	texture_rect.add_child(end_label)
	
	end_label.size = Vector2(600, 150)
	end_label.position = Vector2(
		(texture_rect.size.x - end_label.size.x) / 2,
		(texture_rect.size.y - end_label.size.y) / 2
	)
	
	end_label.modulate.a = 0  
	
	await final_glitch_sequence()
	
	var tween = create_tween()
	tween.set_parallel(true) 
	
	tween.tween_property(end_label, "modulate:a", 1.0, 3.0).set_ease(Tween.EASE_IN)
	
	end_label.scale = Vector2(0.9, 0.9)
	tween.tween_property(end_label, "scale", Vector2(1.0, 1.0), 2.5).set_ease(Tween.EASE_OUT)
	
	skip_button.visible = true
	skip_button.modulate.a = 0 
	tween.tween_property(skip_button, "modulate:a", 1.0, 1.5).set_delay(1.0)  
	Achievements.unlock_achievement(2)
	print("THE END - Bad Ending")

func final_glitch_sequence() -> void:
	for i in range(12):
		glitch_overlay.color = Color(
			randf_range(0.4, 1.4),
			randf_range(0.4, 1.4),
			randf_range(0.4, 1.4),
			randf_range(0.3, 0.5)
		)
		await get_tree().create_timer(0.07).timeout
	
	glitch_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

func start_scrolling():
	is_scrolling = true

func _on_play_pause_button_pressed():
	is_scrolling = !is_scrolling
	
	if is_scrolling:
		play_pause_button.icon = pause_icon 
	else:
		play_pause_button.icon = play_icon  

func _on_back_button_pressed():
	is_scrolling = false
	glitch_active = false
	
	if bgm.playing:
		var tween = create_tween()
		tween.tween_property(bgm, "volume_db", -80.0, 1.0)
		tween.tween_callback(bgm.stop)
		await tween.finished
		
		act_6_scene_2_done()

# ===================
# COMPLETE SCENE
# ===================
func act_6_scene_2_done() -> void:
	SaveManager.game_save.current_act = "act_6"
	SaveManager.game_save.current_scene = "scene_2" 
	SaveManager.save_game()
	print("ACT 6 DONE - The End")

	SignalBus.next_scene.emit("res://scenes/menu/menu_credits.tscn")
		
 