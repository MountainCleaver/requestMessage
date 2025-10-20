extends CanvasLayer

@onready var map_icon = $Map
@onready var full_map = $FullMapPanel

var is_open = false
var fade_duration := 0.2  # seconds

func _ready():
	map_icon.pressed.connect(_toggle_map)
	full_map.modulate.a = 0
	full_map.visible = false

func _input(event):
	if event.is_action_pressed("map"):  # M key
		_toggle_map()

func _toggle_map():
	if is_open:
		is_open = false
		# get_tree().paused = false  # remove this
		await _fade_out()
	else:
		full_map.visible = true
		is_open = true
		# get_tree().paused = true  # remove this
		await _fade_in()

func _fade_in() -> void:
	full_map.modulate.a = 0
	var timer := 0.0
	while timer < fade_duration:
		timer += get_process_delta_time()
		full_map.modulate.a = clamp(timer / fade_duration, 0, 1)
		await get_tree().process_frame
	full_map.modulate.a = 1

func _fade_out() -> void:
	var timer := 0.0
	while timer < fade_duration:
		timer += get_process_delta_time()
		full_map.modulate.a = clamp(1 - (timer / fade_duration), 0, 1)
		await get_tree().process_frame
	full_map.modulate.a = 0
	full_map.visible = false
