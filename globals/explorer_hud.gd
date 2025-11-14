extends CanvasLayer

# ===================
# NODES
# ===================
@onready var map_icon: TouchScreenButton = $Map
@onready var flashlight_button: TouchScreenButton = $Flashlight
@onready var full_map = $FullMapPanel

@onready var map_guide = $Map/Guide
@onready var flashlight_guide = $Flashlight/Guide


@onready var sfx_map: AudioStreamPlayer = $SFX_MAP

@onready var location_nodes = [
	$FullMapPanel/current_map/location_1,
	$FullMapPanel/current_map/location_2,
	$FullMapPanel/current_map/location_3,
	$FullMapPanel/current_map/location_4,
	$FullMapPanel/current_map/location_5,
	$FullMapPanel/current_map/location_6
]

# ===================
# VARIABLES
# ===================
var is_open := false
var fade_duration := 0.2
var guide_fade_time := 0.5
var tutorial_active := false

var map_guide_tween: Tween
var flashlight_guide_tween: Tween

var flashlight_on: bool = false
var can_use_real: bool = true
var can_use_phone: bool = true
# ===================
# READY
# ===================
func _ready():
	flashlight_button.visible = false

	# Hide guides initially
	_init_guide(map_guide)
	_init_guide(flashlight_guide)

	full_map.visible = false
	full_map.modulate.a = 0

	# ===================
	# TOUCH INPUT
	# ===================
	map_icon.pressed.connect(Callable(self, "_on_map_pressed"))
	flashlight_button.pressed.connect(Callable(self, "_on_flashlight_pressed"))

	# ===================
	# MANAGER SIGNALS
	# ===================
	FlashlightManager.connect("real_flashlight_unlocked_signal", Callable(self, "_on_flashlight_unlocked"))
	FlashlightManager.connect("current_scene_changed", Callable(self, "_on_scene_changed"))

	_update_flashlight_visibility()
	_update_guide_keys()
	_check_tutorial_guides()

# ===================
# GUIDE INIT
# ===================
func _init_guide(guide: Control):
	guide.visible = false
	guide.modulate.a = 0

# ===================
# UPDATE KEY LABELS
# ===================
func _get_key_text(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		return events[0].as_text().trim_suffix(" (Physical)")
	return "(None)"

func _update_guide_keys():
	map_guide.get_node("Label").text = "A map… maybe it will help."
	flashlight_guide.get_node("Label").text = "The darkness seems thinner now."

# ===================
# LOCATION HIGHLIGHT
# ===================
func show_current_location(index):
	for i in range(location_nodes.size()):
		location_nodes[i].visible = (i + 1 == index)

# ===================
# TOUCH ACTION HANDLERS
# ===================
func _on_map_pressed():
	sfx_map.play()
	_toggle_map()



func _on_flashlight_pressed():
	if FlashlightManager.can_use_real_flashlight():
		flashlight_on = !flashlight_on
		FlashlightManager.real_flashlight_enabled = flashlight_on
		FlashlightManager._update_lights()

# ===================
# SCENE CHANGE
# ===================
func _on_scene_changed(act: String, scene: String):
	_fade_out_guide(map_guide)
	_fade_out_guide(flashlight_guide)

	_update_flashlight_visibility()
	_update_guide_keys()
	_check_tutorial_guides()

# ===================
# FLASHLIGHT UNLOCKED
# ===================
func _on_flashlight_unlocked():
	if not flashlight_button.visible:
		flashlight_button.visible = true
		flashlight_button.modulate.a = 0
		create_tween().tween_property(flashlight_button, "modulate:a", 1.0, 0.3)

	_fade_in_guide(flashlight_guide)

	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(func(): _fade_out_guide(flashlight_guide))

# ===================
# FLASHLIGHT VISIBILITY RULES
# ===================
func _update_flashlight_visibility():
	var act = FlashlightManager.data.get("current_act", "")
	var scene = FlashlightManager.data.get("current_scene", "")

	flashlight_button.visible = false
	_fade_out_guide(flashlight_guide)

	var scene_number = int(scene.replace("scene_", "0"))
	var show := false

	if act == "act_4":
		if scene_number == 1:
			show = FlashlightManager.real_flashlight_unlocked
		else:
			show = FlashlightManager.real_flashlight_unlocked or SaveManager.has_given_lola_ising_cash()
	elif act == "act_5":
		show = FlashlightManager.real_flashlight_unlocked or SaveManager.has_given_lola_ising_cash()

	if show:
		flashlight_button.visible = true
		flashlight_button.modulate.a = 1.0

# ===================
# TUTORIAL GUIDES
# ===================
func _check_tutorial_guides():
	var act = FlashlightManager.data.get("current_act", "")
	var scene = FlashlightManager.data.get("current_scene", "")

	if act == "act_4" and scene == "scene_1":
		tutorial_active = true
		_fade_in_guide(map_guide)

		if FlashlightManager.real_flashlight_unlocked:
			_fade_in_guide(flashlight_guide)

		var timer := Timer.new()
		timer.wait_time = 5.0
		timer.one_shot = true
		timer.autostart = true
		add_child(timer)
		timer.timeout.connect(Callable(self, "_end_tutorial_guides"))
	else:
		tutorial_active = false
		_fade_out_guide(map_guide)
		_fade_out_guide(flashlight_guide)

func _end_tutorial_guides():
	tutorial_active = false
	_fade_out_guide(map_guide)
	_fade_out_guide(flashlight_guide)

# ===================
# GUIDE FADE HELPERS
# ===================
func _fade_in_guide(guide: Control):
	if guide == map_guide and map_guide_tween: map_guide_tween.kill()
	if guide == flashlight_guide and flashlight_guide_tween: flashlight_guide_tween.kill()

	guide.visible = true
	guide.modulate.a = max(guide.modulate.a, 0)

	var tween = create_tween()
	tween.tween_property(guide, "modulate:a", 1.0, guide_fade_time)

	if guide == map_guide:
		map_guide_tween = tween
	else:
		flashlight_guide_tween = tween

func _fade_out_guide(guide: Control):
	if guide == map_guide and map_guide_tween: map_guide_tween.kill()
	if guide == flashlight_guide and flashlight_guide_tween: flashlight_guide_tween.kill()

	var tween = create_tween()
	tween.tween_property(guide, "modulate:a", 0.0, guide_fade_time)
	tween.finished.connect(Callable(guide, "hide"))

	if guide == map_guide:
		map_guide_tween = tween
	else:
		flashlight_guide_tween = tween

# ===================
# MAP FADE ANIM
# ===================
func _toggle_map():
	if is_open:
		is_open = false
		await _fade_out()
	else:
		full_map.visible = true
		is_open = true
		await _fade_in()

	SignalBus.map_toggled.emit(is_open)

func _fade_in() -> void:
	full_map.modulate.a = 0
	var t := 0.0
	while t < fade_duration:
		t += get_process_delta_time()
		full_map.modulate.a = clamp(t / fade_duration, 0, 1)
		await get_tree().process_frame
	full_map.modulate.a = 1

func _fade_out() -> void:
	var t := 0.0
	while t < fade_duration:
		t += get_process_delta_time()
		full_map.modulate.a = clamp(1 - (t / fade_duration), 0, 1)
		await get_tree().process_frame
	full_map.modulate.a = 0
	full_map.visible = false
