extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label_lines: RichTextLabel = $lines
@onready var sfx_start: AudioStreamPlayer = $SFX_START
@onready var BGM_GOOD: AudioStreamPlayer = $BGM_GOOD
@onready var BGM_BAD: AudioStreamPlayer = $BGM_BAD

var outro_lines: Array = []
var is_good_ending: bool = false
var line_index: int = 0
var fade_time: float = 1.0
var display_time: float = 2.0

var base_position_lines: Vector2
var motion_seed_lines: float
var time_acc: float = 0.0

# ================================
# Load outro dialogue from JSON
# ================================
func _load_dialogue() -> void:
	# Pick JSON file based on language
	var lang = Settings.settings.dialogue_language
	var path: String = "res://dialogues/intro_outro/a5s8_outro_en.json" if lang == "en" else "res://dialogues/intro_outro/a5s8_outro.json"

	# Check if file exists
	if not FileAccess.file_exists(path):
		push_error("Dialogue JSON file not found: %s" % path)
		outro_lines = []
		line_index = 0
		return

	# Open and read JSON file
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	# Parse JSON
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Failed to parse dialogue JSON properly: %s" % path)
		outro_lines = []
		line_index = 0
		return

	# Get correct array
	if is_good_ending:
		outro_lines = parsed.get("good", [])
	else:
		outro_lines = parsed.get("bad", [])

	line_index = 0



func _ready() -> void:
	var total_karma = 0
	if "get_total_karma" in SaveManager:
		total_karma = SaveManager.get_total_karma()
	else:
		print("⚠️ SaveManager not initialized, defaulting to bad ending.")

	is_good_ending = total_karma > 0

	_load_dialogue()

	label_lines.modulate.a = 0
	label_lines.bbcode_enabled = true
	base_position_lines = label_lines.position
	motion_seed_lines = randf() * 10.0

	# ===============================
	# CHOOSE OUTRO BASED ON KARMA
	# ===============================
	if total_karma > 0:
		is_good_ending = true
		print("🎵 Good ending: Finally at Rest")
		_play_bgm_good()
	else:
		is_good_ending = false
		print("🎵 Bad ending: Unending Guilt")
		_play_bgm_bad()

	await get_tree().create_timer(2.5).timeout
	show_next_line()



func _play_bgm_good() -> void:
	if BGM_BAD.playing:
		BGM_BAD.stop()
	if not BGM_GOOD.playing:
		BGM_GOOD.play()


func _play_bgm_bad() -> void:
	if BGM_GOOD.playing:
		BGM_GOOD.stop()
	if not BGM_BAD.playing:
		BGM_BAD.play()


func _process(delta: float) -> void:
	time_acc += delta
	if label_lines.modulate.a > 0:
		var angle = time_acc * 2.0 + motion_seed_lines
		var radius_x = 4 + sin(time_acc * 1.0 + motion_seed_lines) * 4
		var radius_y = 3 + cos(time_acc * 1.3 + motion_seed_lines * 1.5) * 3
		label_lines.position = base_position_lines + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)


func show_next_line() -> void:
	if line_index < outro_lines.size():
		label_lines.clear()
		label_lines.parse_bbcode(outro_lines[line_index])
		line_index += 1
		base_position_lines = label_lines.position
		motion_seed_lines = randf() * 10.0
		fade_in_label(label_lines)
	else:
		await get_tree().create_timer(2.0).timeout
		_act_5_scene_8_done()


func fade_in_label(label: RichTextLabel) -> void:
	label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1, fade_time)
	tween.tween_callback(func(): _on_fade_in_complete(label))


func _on_fade_in_complete(label: RichTextLabel) -> void:
	await get_tree().create_timer(display_time).timeout
	fade_out_label(label)


func fade_out_label(label: RichTextLabel) -> void:
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0, fade_time)
	tween.tween_callback(func(): show_next_line())


func _act_5_scene_8_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_8"
	SaveManager.save_game()
	SignalBus.act_num_scene_num_done.emit("act_5", "scene_8", "res://scenes/game/act_6_title_scene.tscn")


func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
