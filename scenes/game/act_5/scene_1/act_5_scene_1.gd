extends Node2D 

# ===================
# PRELOADS
# ===================
var A_5S_1: Resource
const DARK_FOREST = preload("res://scenes/game/act_5/scene_1/dark_forest.tscn")
const CHAPEL_EXTERIOR = preload("res://scenes/game/act_5/scene_1/chapel_exterior.tscn")
const CHAPEL_INTERIOR = preload("res://scenes/game/act_5/scene_1/chapel_interior.tscn")
const NARRATION_PANEL = preload("res://helpers/narration_panel.tscn")

@onready var sfx_light : AudioStreamPlayer = $SFX_LIGHTER

# ===================
# NODES
# ===================
@onready var locations: Node2D = $locations
@onready var explorer_hud: CanvasLayer = $explorer_hud
var player_danilo: CharacterBody2D
var tip_interact: Sprite2D
var animated_sprite_2d: AnimatedSprite2D
var current_location: Node
var anim_player: AnimationPlayer
var dizzy_overlay: ColorRect
# Areas
var dark_forest_entrance_area: Area2D
var door_area: Area2D
var before_door_area: Area2D
var altar_area_1: Area2D
var altar_area_2: Area2D
var can_sit_altar_1 := false
var can_sit_altar_2 := false
var dizzy_duration := 1.5
var dizzy_timer: Timer = null

# ===================
# OBJECTIVES
# ===================
var scene_objectives = [
	{"ID": 1, "text": "Return to the old chapel"},
	{"ID": 2, "text": "Light up all the candles"},
	{"ID": 3, "text": "Sit at the altar to begin reading"}
]

# ===================
# FLAGS
# ===================
var door_interacted = false
var can_use_door = false
var dialogue_triggered = false

var narration_panel_showed : bool = false

var can_interact_candle := false
var candle_ignited := false
var lit_candles := {} 
var total_candles := 7

# ===================
# READY
# ===================
func _ready():
	_game_state_flow()
	_load_dialogue()
	switch_location(DARK_FOREST)
	_start_scene()
	SignalBus.unknown_sender_unlocked = true
	SignalBus.unknown_sender_label_visible = false

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_5/scene_1/a5s1_en.dialogue"
	else:
		path = "res://dialogues/act_5/scene_1/a5s1.dialogue"
	
	A_5S_1 = load(path)
	
func _game_state_flow() -> void:
	FlashlightManager.set_current_scene("act_5", "scene_1")
	FlashlightManager.enable_flashlight_by_cash()
	GameState.load_game()
	GameState.current_act = "act_5"
	GameState.current_scene = "scene_1"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()

# ===================
# START SCENE
# ===================
func _start_scene() -> void:
	await get_tree().process_frame
	_trigger_dizzy_effect()
	explorer_hud.show_current_location(3)
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	DialogueManager.show_dialogue_balloon(A_5S_1, "start")

func _on_dark_forest_entrance_entered(body: Node) -> void:
	if body != player_danilo:
		return 
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_switch_to_chapel_exterior()

# ===================
# SWITCH LOCATIONS
# ===================
func _switch_to_chapel_exterior() -> void:
	await get_tree().process_frame
	switch_location(CHAPEL_EXTERIOR)
	explorer_hud.show_current_location(5)

func _switch_to_chapel_interior(from_where: String = "default") -> void:
	await get_tree().process_frame
	switch_location(CHAPEL_INTERIOR)
	explorer_hud.show_current_location(5)

	# Spawn player depending on which path triggered
	var spawn_marker: Node2D = null
	if from_where == "first_entry":
		spawn_marker = current_location.get_node_or_null("spawn_marker_1")
	elif from_where == "after_arrange_pages":
		spawn_marker = current_location.get_node_or_null("spawn_marker_2")

	if spawn_marker and player_danilo:
		player_danilo.global_position = spawn_marker.global_position

	match from_where:
		"first_entry":
			_trigger_dizzy_effect()
			player_danilo.last_direction = Vector2.UP
			DialogueManager.show_dialogue_balloon(A_5S_1, "light_candle")
			await DialogueManager.dialogue_ended
			ObjectiveManager.add_progress_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"], total_candles)
			_setup_all_candle_areas()
		
		"after_arrange_pages":
			# Re-light all candles visually when coming back
			for index in lit_candles.keys():
				var sprite_path = "map/candle/big_candle/candle" if index == 0 else "map/candle/candle_%d/candle" % index
				var light_path = "map/candle/big_candle/PointLight2D" if index == 0 else "map/candle/candle_%d/PointLight2D" % index

				var sprite: Sprite2D = current_location.get_node_or_null(sprite_path)
				var light: PointLight2D = current_location.get_node_or_null(light_path)

				if sprite:
					sprite.region_enabled = true
					sprite.region_rect = Rect2(21, 0, 20.8, 29) if index == 0 else Rect2(9,0,9,20)
				if light:
					light.visible = true
					light.texture_scale = 1.7 if index == 0 else 5.0

			player_danilo.last_direction = Vector2.UP
			DialogueManager.show_dialogue_balloon(A_5S_1, "after_arrange_pages")
			await DialogueManager.dialogue_ended
			Hud.show_objectives()
			ObjectiveManager.add_objective(scene_objectives[2]["ID"], scene_objectives[2]["text"])



# ===================
# LOCATION HANDLER
# ===================
func switch_location(scene: PackedScene) -> void:
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	current_location = scene.instantiate()
	locations.add_child(current_location)

	player_danilo = current_location.get_node_or_null("y-sorted/player_danilo")
	tip_interact = player_danilo.get_node_or_null("tip_interact") if player_danilo else null
	animated_sprite_2d = player_danilo.get_node_or_null("AnimatedSprite2D") if player_danilo else null
	anim_player = current_location.get_node_or_null("AnimationPlayer")

	door_area = current_location.get_node_or_null("door_area")
	before_door_area = current_location.get_node_or_null("before_door_area")
	dizzy_overlay = current_location.get_node_or_null("ColorRect")
	
	if dizzy_overlay:
		dizzy_overlay.visible = false
	if scene == DARK_FOREST:
		dark_forest_entrance_area = current_location.get_node_or_null("entrance")
	if dark_forest_entrance_area:
		dark_forest_entrance_area.body_entered.connect(_on_dark_forest_entrance_entered)
	if before_door_area:
		before_door_area.body_entered.connect(_on_before_door_area_body_entered)
	if door_area:
		door_area.body_entered.connect(_on_door_area_body_entered)
		door_area.body_exited.connect(_on_door_area_body_exited)
		
	altar_area_1 = current_location.get_node_or_null("altar_area_1")
	altar_area_2 = current_location.get_node_or_null("altar_area_2")

	if altar_area_1:
		altar_area_1.body_entered.connect(_on_altar_area_1_entered)
		altar_area_1.body_exited.connect(_on_altar_area_1_exited)

	if altar_area_2:
		altar_area_2.body_entered.connect(_on_altar_area_2_entered)
		altar_area_2.body_exited.connect(_on_altar_area_2_exited)


# ===================
# AREA HANDLERS
# ===================
func _on_before_door_area_body_entered(body):
	if body == player_danilo and not dialogue_triggered:
		dialogue_triggered = true
		player_danilo.set_physics_process(false)
		_trigger_dizzy_effect()
		DialogueManager.show_dialogue_balloon(A_5S_1, "back_to_chapel_again")
		player_danilo.set_physics_process(true)

func _on_door_area_body_entered(body):
	if body == player_danilo and not door_interacted:
		can_use_door = true
		if tip_interact:
			tip_interact.visible = true

func _on_door_area_body_exited(body):
	if body == player_danilo:
		can_use_door = false
		if tip_interact:
			tip_interact.visible = false

func _on_altar_area_1_entered(body):
	if body == player_danilo:
		# Only allow sitting if all candles are lit
		if lit_candles.size() >= total_candles and narration_panel_showed:
			can_sit_altar_1 = true
			if tip_interact:
				tip_interact.visible = true

func _on_altar_area_1_exited(body):
	if body == player_danilo:
		can_sit_altar_1 = false
		if tip_interact:
			tip_interact.visible = false

func _on_altar_area_2_entered(body):
	if body == player_danilo:
		# Only allow sitting if all candles are lit
		if lit_candles.size() >= total_candles and narration_panel_showed:
			can_sit_altar_2 = true
			if tip_interact:
				tip_interact.visible = true

func _on_altar_area_2_exited(body):
	if body == player_danilo:
		can_sit_altar_2 = false
		if tip_interact:
			tip_interact.visible = false


# ===================
# INPUT HANDLER
# ===================
func _process(_delta):
	# Door interaction
	if can_use_door and not door_interacted and Input.is_action_just_pressed("interact"):
		_door_interacted()

	# Candle interaction
	if can_interact_candle and Input.is_action_just_pressed("interact"):
		var candle_index = current_location.get_meta("current_candle")
		if candle_index != null and not lit_candles.has(candle_index):
			_light_candle(candle_index)
	# Sit at altar interaction

	if can_sit_altar_1 and Input.is_action_just_pressed("interact"):
			_sit_at_marker_1()
	elif can_sit_altar_2 and Input.is_action_just_pressed("interact"):
			_sit_at_marker_2()

# ===================
# INTERACTIONS
# ===================
func _door_interacted():
	door_interacted = true
	can_use_door = false
	if tip_interact:
		tip_interact.visible = false
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	ObjectiveManager.complete_objective(1)
	_switch_to_chapel_interior("first_entry")

# ===================
# CANDLE LOGIC
# ===================



func _setup_all_candle_areas() -> void:
	# Big candle
	var big_area = current_location.get_node_or_null("map/candle/big_candle/big_candle_area")
	if big_area:
		big_area.visible = true
		big_area.monitoring = true
		big_area.body_entered.connect(_on_candle_area_entered.bind(0)) # index 0 = big candle
		big_area.body_exited.connect(_on_candle_area_exited.bind(0))

	# Small candles 1-6
	for i in range(1, 7):
		var area = current_location.get_node_or_null("map/candle/candle_%d/candle_%d_area" % [i, i])
		if area:
			area.visible = true
			area.monitoring = true
			area.body_entered.connect(_on_candle_area_entered.bind(i))
			area.body_exited.connect(_on_candle_area_exited.bind(i))
		var sprite = current_location.get_node_or_null("map/candle/candle_%d/candle" % i)
		if sprite:
			sprite.region_rect = Rect2(0, 0, 9.6, 20)
		var light = current_location.get_node_or_null("map/candle/candle_%d/PointLight2D" % i)
		if light:
			light.visible = false

	# Big candle sprite/light
	if big_area:
		var big_sprite = current_location.get_node_or_null("map/candle/big_candle/candle")
		if big_sprite:
			big_sprite.region_rect = Rect2(0,0,20,29)
		var big_light = current_location.get_node_or_null("map/candle/big_candle/PointLight2D")
		if big_light:
			big_light.visible = false

func _on_candle_area_entered(body, index: int) -> void:
	if body != player_danilo:
		return
	
	# Only show tip if candle not yet lit
	if lit_candles.has(index):
		can_interact_candle = false
		if tip_interact:
			tip_interact.visible = false
		return
	
	can_interact_candle = true
	current_location.set_meta("current_candle", index)
	if tip_interact:
		tip_interact.visible = true
		
func _on_candle_area_exited(body, index: int) -> void:
	if body != player_danilo:
		return
	can_interact_candle = false
	current_location.set_meta("current_candle", null)
	if tip_interact:
		tip_interact.visible = false


func _light_candle(index: int) -> void:
	sfx_light.play()
	lit_candles[index] = true

	# Visuals
	var sprite_path = "map/candle/big_candle/candle" if index == 0 else "map/candle/candle_%d/candle" % index
	var light_path = "map/candle/big_candle/PointLight2D" if index == 0 else "map/candle/candle_%d/PointLight2D" % index

	var sprite: Sprite2D = current_location.get_node_or_null(sprite_path)
	var light: PointLight2D = current_location.get_node_or_null(light_path)

	if sprite:
		sprite.region_enabled = true
		sprite.region_rect = Rect2(21, 0, 20.8, 29) if index == 0 else Rect2(9,0,9,20)
	if light:
		light.visible = true
		light.texture_scale = 0.5
		var tween = create_tween()
		tween.tween_property(light, "texture_scale", 1.7 if index==0 else 5.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if tip_interact:
		tip_interact.visible = false

	ObjectiveManager.update_progress(scene_objectives[1]["ID"])

	if lit_candles.size() >= total_candles:
		ObjectiveManager.complete_objective(scene_objectives[1]["ID"])
		await get_tree().create_timer(1).timeout
		Hud.hide_objectives()
		Hud.clear_objectives()
		# Switch location to narration panel
		TransitionFade.transition()
		await SignalBus.on_transition_finished
		switch_location(NARRATION_PANEL)
		await get_tree().process_frame

		var lines = [
			"The candles burn without wavering,",
			"as I carefully arrange each pages.",
			"The room feels still, waiting for something to begin."
		]

		await NarrationPanel.show_narration_typewriter(lines, 0.05)
		await NarrationPanel.hide_narration()

		TransitionFade.transition()
		await SignalBus.on_transition_finished
		narration_panel_showed = true
		_switch_to_chapel_interior("after_arrange_pages")

func _sit_at_marker_1():
	if tip_interact:
		tip_interact.visible = false
	var sit_marker = current_location.get_node_or_null("sit_marker_1")

	if sit_marker and player_danilo:
		player_danilo.global_position = sit_marker.global_position
		player_danilo.can_move = false
		read_notebook(sit_marker)
		
		ObjectiveManager.complete_objective(3)
		Hud.hide_objectives()
		
		if anim_player:
			anim_player.play("zoom_in")
			await anim_player.animation_finished
		scene_3_done()


func _sit_at_marker_2():
	if tip_interact:
		tip_interact.visible = false
	var sit_marker = current_location.get_node_or_null("sit_marker_2")
	var sprite: AnimatedSprite2D = player_danilo.get_node_or_null("AnimatedSprite2D") if player_danilo else null
	
	if sit_marker and player_danilo:
		player_danilo.global_position = sit_marker.global_position
		player_danilo.can_move = false
		read_notebook(sit_marker)
			
		ObjectiveManager.complete_objective(3)
		Hud.hide_objectives()
		
		if anim_player:
			anim_player.play("zoom_in")
			await anim_player.animation_finished
		scene_3_done()
		

func _trigger_dizzy_effect():
	var meds_taken := SaveManager.get_count_meds_taken()  # or your function
	if meds_taken > 1:
		return  # Skip if player took 2+ meds

	if not dizzy_overlay:
		return

	dizzy_overlay.visible = true
	var t := Timer.new()
	t.wait_time = dizzy_duration
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(func():
		dizzy_overlay.visible = false
		t.queue_free()
	)
	add_child(t)
	
func _start_dizzy_timer():
	if dizzy_timer:
		dizzy_timer.queue_free()

	dizzy_timer = Timer.new()
	dizzy_timer.wait_time = 30.0 
	dizzy_timer.one_shot = false
	dizzy_timer.autostart = true
	dizzy_timer.timeout.connect(_trigger_dizzy_effect)
	add_child(dizzy_timer)
# ===================
# COMPLETE SCENE
# ===================
func scene_3_done() -> void:
	Hud.clear_objectives()
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_1"
	SaveManager.save_game()
	GameState.save_game()
	print("ACT 5 SCENE 1 DONE")
	SignalBus.act_num_scene_num_done.emit(
		"act_5", 
		"scene_1", 
        "res://scenes/game/act_5/scene_2/act_5_scene_2.tscn"
	)

func read_notebook(sit_marker: Node2D) -> void:
	if not player_danilo:
		push_warning("Player node not found!")
		return
	
	var original_position = player_danilo.global_position
	player_danilo.animation_locked = true
	player_danilo.can_move = false
	
	# Move player to the sit marker position
	if sit_marker:
		player_danilo.global_position = sit_marker.global_position
	
	var sprite: AnimatedSprite2D = player_danilo.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.flip_h = false  # fix facing direction if needed
		sprite.z_index = 1000
		sprite.play("read_notebook")
		await sprite.animation_finished
	else:
		# fallback wait duration if animation missing
		await get_tree().create_timer(1.0).timeout
	
	player_danilo.animation_locked = false
	player_danilo.can_move = true
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
