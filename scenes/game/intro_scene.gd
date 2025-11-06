extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label_lines: Label = $lines
@onready var game_title: Label = $game_title
@onready var sfx_start: AudioStreamPlayer = $SFX_START
#@onready var bgm_start: AudioStreamPlayer = $BGM_START

var intro_lines: Array = []
var line_index: int = 0

var fade_time = 1.0
var display_time = 2.0

# Motion control
var base_position_lines: Vector2
var base_position_title: Vector2
var motion_seed_lines: float
var motion_seed_title: float
var time_acc: float = 0.0

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String

	if lang == "en":
		path = "res://dialogues/intro_outro/a1s1_intro_en.json"
	else:
		path = "res://dialogues/intro_outro/a1s1_intro.json"

	if not FileAccess.file_exists(path):
		push_error("Dialogue JSON file not found: %s" % path)
		intro_lines = []
		line_index = 0
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	intro_lines = JSON.parse_string(text)
	line_index = 0

	if intro_lines.size() == 0:
		push_error("Dialogue JSON is empty or failed to parse: %s" % path)


func _ready() -> void:
	label_lines.modulate.a = 0
	game_title.modulate.a = 0

	base_position_lines = label_lines.position
	base_position_title = game_title.position
	motion_seed_lines = randf() * 10.0
	motion_seed_title = randf() * 10.0

	_load_dialogue()

	await get_tree().create_timer(3.0).timeout
	show_next_line()


func _process(delta: float) -> void:
	time_acc += delta

	if label_lines.modulate.a > 0:
		var angle = time_acc * 2.0 + motion_seed_lines
		var radius_x = 4 + sin(time_acc * 1.0 + motion_seed_lines) * 4
		var radius_y = 3 + cos(time_acc * 1.3 + motion_seed_lines * 1.5) * 3
		label_lines.position = base_position_lines + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)

	if game_title.modulate.a > 0:
		var angle = time_acc * 1.2 + motion_seed_title
		var radius_x = 5 + sin(time_acc * 0.7 + motion_seed_title) * 5
		var radius_y = 4 + cos(time_acc * 0.9 + motion_seed_title * 1.3) * 4
		game_title.position = base_position_title + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)


func show_next_line() -> void:
	if line_index < intro_lines.size():
		label_lines.text = intro_lines[line_index]
		line_index += 1

		base_position_lines = label_lines.position
		motion_seed_lines = randf() * 10.0

		fade_in_label(label_lines, false)
	else:
		await get_tree().create_timer(3.0).timeout
		game_title.text = "Request Message"
		base_position_title = game_title.position
		motion_seed_title = randf() * 10.0
		#bgm_start.stop()
		sfx_start.play()
		fade_in_label(game_title, true)


func fade_in_label(label: Label, is_title: bool) -> void:
	label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1, fade_time)
	tween.tween_callback(func() -> void:
		_on_fade_in_complete(label, is_title)
	)


func _on_fade_in_complete(label: Label, is_title: bool) -> void:
	if is_title:
		await get_tree().create_timer(5.0).timeout
		fade_out_label_title()
	else:
		await get_tree().create_timer(display_time).timeout
		fade_out_label(label)


func fade_out_label(label: Label) -> void:
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0, fade_time)
	tween.tween_callback(func() -> void:
		show_next_line()
	)


func fade_out_label_title() -> void:
	var tween = create_tween()
	tween.tween_property(game_title, "modulate:a", 0, fade_time)
	tween.tween_callback(func() -> void:
		await get_tree().create_timer(2.0).timeout
		_go_to_next_scene()
	)


func _go_to_next_scene() -> void:
	SignalBus.next_scene.emit("res://scenes/game/act_1_title_scene.tscn")
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
