extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label_lines: RichTextLabel = $lines
@onready var sfx_start: AudioStreamPlayer = $SFX_START
@onready var BGM_GOOD: AudioStreamPlayer = $BGM_GOOD
@onready var BGM_BAD: AudioStreamPlayer = $BGM_BAD

# ================================
# OUTRO LINES (Good vs Bad Ending)
# ================================

var outro_lines_relief = [
	"My vision’s fading...",
	"I can still feel the wind against my skin.",
	"I did it... I finally found him.",
	"Mateo’s smile... it felt so peaceful.",
	"Maybe... this time... he’s really at rest.",
	"My body’s weak... but my heart feels light.",
	"I can’t tell if I’m still dreaming or if this is goodbye.",
	"Mateo... you’re finally at rest.",
	"I think... I can rest too.",
]

var outro_lines_restless = [
	"[shake rate=10 level=10]My vision’s fading....[/shake]",
	"[shake rate=10 level=12]I tried... I really tried to reach you...[/shake]",
	"[shake rate=10 level=14]Everything’s spinning... I can’t breathe...[/shake]",
	"[shake rate=10 level=15]Mateo... please... don’t go...[/shake]",
	"[shake rate=10 level=16]The voices... they won’t stop...[/shake]",
	"[shake rate=10 level=18]It’s dark... so dark...[/shake]",
	"[shake rate=10 level=12]I’m sorry... I couldn’t save you...[/shake]",
	"[shake rate=10 level=14]My strength... it’s fading...[/shake]",
	"[shake rate=10 level=18][color=#ff3333]I can’t feel anything anymore...[/color][/shake]"
]

var outro_lines = [] 
var is_good_ending = false

var line_index = 0
var fade_time = 1.0
var display_time = 2.0

var base_position_lines: Vector2
var motion_seed_lines: float
var time_acc: float = 0.0


func _ready() -> void:
	label_lines.modulate.a = 0
	label_lines.bbcode_enabled = true
	base_position_lines = label_lines.position
	motion_seed_lines = randf() * 10.0

	var total_karma = 0
	if "get_total_karma" in SaveManager:
		total_karma = SaveManager.get_total_karma()
	else:
		print("⚠️ SaveManager not initialized, defaulting to restless outro.")

	# ===============================
	# CHOOSE OUTRO BASED ON KARMA
	# ===============================
	if total_karma > 0:
		is_good_ending = true
		outro_lines = outro_lines_relief
		print("🎵 Good ending: Finally at Rest")
		_play_bgm_good()
	else:
		is_good_ending = false
		outro_lines = outro_lines_restless
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
