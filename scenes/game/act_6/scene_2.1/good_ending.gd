extends Node2D

@onready var narration_text: RichTextLabel = $CanvasLayer/Control/Panel/TextureRect/RichTextLabel
@onready var skip_button: Button = $CanvasLayer/Control/Panel/TextureRect/Button
@onready var play_pause_button: Button = $CanvasLayer/Control/Panel/TextureRect/play_pause_button
@onready var bgm: AudioStreamPlayer = $BGMGood

var pause_icon = preload("res://assets/character_sprites/pause.png")  
var play_icon = preload("res://assets/character_sprites/play.png")    

var story_lines = [
	"[center]The next morning, Danilo begged the villagers to go back to the cliff with him. They were unsure, but they saw how much he needed to go, so they agreed. They climbed down the side of the cliff and started to dig in the spot Danilo showed them. After many hours, they found bones. They were small and delicate, the bones of a child who had been missing for a long time. The villagers lit candles and began to pray. Then, a faint image of the boy, Mateo, appeared by the cliff. He was smiling and finally at peace.[/center]",
	"",
	"",
	"[center]He whispered a thank you that only Danilo could hear. Tears fell down Danilo's face. Wendy held his hand tightly. For the first time in fifteen years, the heavy feeling in his heart was gone.[/center]"
]

var current_line_index := 0
var scroll_speed := 22.0
var is_scrolling := true
var initial_y_position := 0.0
var has_shown_end := false
var screen_height := 0.0

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
	
	if bgm.stream != null:
		bgm.play()
	
	await get_tree().create_timer(1.5).timeout
	start_scrolling()

func _process(delta):
	if is_scrolling and not has_shown_end:
		narration_text.position.y -= scroll_speed * delta
		
		var target_lines_bottom = narration_text.position.y + narration_text.size.y
		
		if target_lines_bottom < screen_height * 0.2: 
			show_the_end()

func show_the_end():
	has_shown_end = true
	
	play_pause_button.visible = false
	
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
	
	end_label.add_theme_color_override("font_color", Color(0.389, 0.389, 0.389, 1.0))
	
	$CanvasLayer/Control/Panel/TextureRect.add_child(end_label)
	
	end_label.size = Vector2(600, 150)
	end_label.position = Vector2(
		($CanvasLayer/Control/Panel/TextureRect.size.x - end_label.size.x) / 2,
		($CanvasLayer/Control/Panel/TextureRect.size.y - end_label.size.y) / 2
	)
	
	end_label.modulate.a = 0  
	
	var tween = create_tween()
	tween.set_parallel(true) 
	
	tween.tween_property(end_label, "modulate:a", 1.0, 3.0).set_ease(Tween.EASE_IN)
	
	end_label.scale = Vector2(0.9, 0.9)
	tween.tween_property(end_label, "scale", Vector2(1.0, 1.0), 2.5).set_ease(Tween.EASE_OUT)
	
	skip_button.visible = true
	skip_button.modulate.a = 0 
	tween.tween_property(skip_button, "modulate:a", 1.0, 1.5).set_delay(1.0)  
	print("THE END!")

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
	
	if bgm.playing:
		var tween = create_tween()
		tween.tween_property(bgm, "volume_db", -80.0, 1.0)
		tween.tween_callback(bgm.stop)
		await tween.finished
	
	get_tree().change_scene_to_file("res://scenes/menu/menu_credits.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept") and not has_shown_end:
		_on_play_pause_button_pressed()
	
	if event.is_action_pressed("ui_accept") and has_shown_end:
		_on_back_button_pressed()
	
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
