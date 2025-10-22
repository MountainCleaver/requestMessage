extends CanvasLayer

# ===================
# NODES
# ===================
@onready var map_icon = $Map
@onready var full_map = $FullMapPanel
@onready var flashlight_button = $Flashlight
@onready var map_guide = $Map/Panel/Label/Guide
@onready var flashlight_guide = $Flashlight/Panel/Label/Guide

# ===================
# VARIABLES
# ===================
var is_open = false
var fade_duration := 0.2
var guide_fade_time := 0.5  
var tutorial_active := false 

var map_guide_tween: Tween
var flashlight_guide_tween: Tween

# ===================
# READY
# ===================
func _ready():
	flashlight_button.visible = false
	map_guide.visible = false
	map_guide.modulate.a = 0
	flashlight_guide.visible = false
	flashlight_guide.modulate.a = 0
	full_map.visible = false
	full_map.modulate.a = 0

	map_icon.pressed.connect(_toggle_map)

	FlashlightManager.connect("real_flashlight_unlocked_signal", Callable(self, "_on_flashlight_unlocked"))
	FlashlightManager.connect("current_scene_changed", Callable(self, "_on_scene_changed"))

	map_icon.mouse_entered.connect(Callable(self, "_on_map_hover"))
	map_icon.mouse_exited.connect(Callable(self, "_on_hover_exit"))
	flashlight_button.mouse_entered.connect(Callable(self, "_on_flashlight_hover"))
	flashlight_button.mouse_exited.connect(Callable(self, "_on_hover_exit"))

	_update_flashlight_visibility()

	_check_tutorial_guides()

# ===================
# TUTORIAL GUIDE LOGIC
# ===================
func _check_tutorial_guides():
	var act = FlashlightManager.data.get("current_act", "")
	var scene = FlashlightManager.data.get("current_scene", "")

	if act == "act_4" and scene == "scene_1":
		tutorial_active = true
		_fade_in_guide(map_guide)

		if FlashlightManager.real_flashlight_unlocked:
			_fade_in_guide(flashlight_guide)

		var timer = Timer.new()
		timer.wait_time = 7.0
		timer.one_shot = true
		timer.autostart = true
		add_child(timer)
		timer.timeout.connect(Callable(self, "_end_tutorial_guides"))

func _end_tutorial_guides():
	tutorial_active = false
	_fade_out_guide(map_guide)
	_fade_out_guide(flashlight_guide)

# ===================
# GUIDE FADE HELPERS
# ===================
func _fade_in_guide(guide: Control):
	if guide == map_guide and map_guide_tween:
		map_guide_tween.kill()
	elif guide == flashlight_guide and flashlight_guide_tween:
		flashlight_guide_tween.kill()

	guide.visible = true
	guide.modulate.a = max(guide.modulate.a, 0)

	var tween = create_tween()
	tween.tween_property(guide, "modulate:a", 1.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if guide == map_guide:
		map_guide_tween = tween
	else:
		flashlight_guide_tween = tween

func _fade_out_guide(guide: Control):
	if guide == map_guide and map_guide_tween:
		map_guide_tween.kill()
	elif guide == flashlight_guide and flashlight_guide_tween:
		flashlight_guide_tween.kill()

	var tween = create_tween()
	tween.tween_property(guide, "modulate:a", 0.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(Callable(guide, "hide"))

	if guide == map_guide:
		map_guide_tween = tween
	else:
		flashlight_guide_tween = tween

# ===================
# HOVER HANDLERS
# ===================
func _on_map_hover():
	if not tutorial_active:
		_fade_in_guide(map_guide)

func _on_flashlight_hover():
	if not tutorial_active and flashlight_button.visible:
		_fade_in_guide(flashlight_guide)

func _on_hover_exit():
	if not tutorial_active:
		_fade_out_guide(map_guide)
		_fade_out_guide(flashlight_guide)

# ===================
# SCENE CHANGED
# ===================
func _on_scene_changed(act: String, scene: String):
	_update_flashlight_visibility()
	_check_tutorial_guides()

# ===================
# FLASHLIGHT SIGNAL
# ===================
func _on_flashlight_unlocked():
	if not flashlight_button.visible:
		flashlight_button.visible = true
		flashlight_button.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(flashlight_button, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		print("[ExplorerHUD] Flashlight button visible")

	_fade_in_guide(flashlight_guide)

	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(Callable(self, "_fade_out_guide").bind(flashlight_guide))

# ===================
# UPDATE FLASHLIGHT VISIBILITY
# ===================
func _update_flashlight_visibility():
	var act = FlashlightManager.data.get("current_act", "")
	var scene = FlashlightManager.data.get("current_scene", "")

	if act != "act_4":
		flashlight_button.visible = false
		return

	var scene_number = int(scene.replace("scene_", "0"))

	var should_show_button = false

	if scene_number == 1:
		if FlashlightManager.real_flashlight_unlocked:
			should_show_button = true
	else:
		if FlashlightManager.real_flashlight_unlocked or SaveManager.has_given_lola_ising_cash():
			should_show_button = true

	if should_show_button and not flashlight_button.visible:
		flashlight_button.visible = true
		flashlight_button.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(flashlight_button, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		_fade_in_guide(flashlight_guide)

	elif not should_show_button:
		flashlight_button.visible = false


# ===================
# MAP TOGGLE & FADE
# ===================
func _input(event):
	if event.is_action_pressed("map"):
		_toggle_map()

func _toggle_map():
	if is_open:
		is_open = false
		await _fade_out()
	else:
		full_map.visible = true
		is_open = true
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
