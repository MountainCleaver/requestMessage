extends Node2D

var A_3S_1: Resource

@onready var player_danilo: CharacterBody2D = $"locations/danilo_hometown/y-sorted-objects/player_danilo"
@onready var npc_lola_ising: CharacterBody2D = $"locations/danilo_hometown/y-sorted-objects/npc_lola_ising"

@onready var bus: AnimatedSprite2D = $"locations/danilo_hometown/y-sorted-objects/bus"
#@onready var bus_animation_player: AnimationPlayer = $"locations/danilo_hometown/y-sorted-objects/bus/AnimationPlayer"
@onready var camera_2d: Camera2D = $Camera2D

@onready var ising_collision_shape_2d: CollisionShape2D = $"locations/danilo_hometown/y-sorted-objects/npc_lola_ising/CollisionShape2D"

@onready var ising_detector: Area2D = $ising_detectors/ising_detector
@onready var ising_turn: Area2D = $ising_detectors/ising_turn
@onready var ising_stop: Area2D = $ising_detectors/ising_stop
@onready var ising_warning: Area2D = $ising_detectors/ising_warning

@onready var wind: AnimatedSprite2D = $wind

@onready var sfx_bus: AudioStreamPlayer = $SFX_BUS
@onready var sfx_wind: AudioStreamPlayer = $SFX_WIND
@onready var navigation_home: Marker2D = $navigation_lights/navigation_home
@onready var navigation_lights: Node2D = $navigation_lights

var lights: Array = []  
var show_navigation := false
var max_lights := 100
var base_distance := 200.0
var light_scene := preload("res://assets/tilesets/nav_light.tscn") 

var intro_anim_done : bool = false;
var lola_ising_reavealed : bool = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SaveManager.reset_lola_ising_progress()
	FlashlightManager.set_current_scene("act_3", "scene_1")
	FlashlightManager.disable_flashlights()
	_load_dialogue()
	ising_collision_shape_2d.disabled = true;
	player_danilo.force_cannot_move = true;
	sfx_bus.play()

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_3/scene_1/a3s1_en.dialogue"
	else:
		path = "res://dialogues/act_3/scene_1/a3s1.dialogue"
	
	A_3S_1 = load(path)
	
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	sfx_bus.stop()
	wind.play("default");
	sfx_wind.play()
	bus.queue_free();
	await wind.animation_finished
	sfx_wind.stop()
	wind.queue_free()
	player_danilo.force_cannot_move = false;
	camera_2d.position = player_danilo.global_position;
	intro_anim_done  = true;
	Hud.clear_objectives()
	ObjectiveManager.add_objective(1, "Find your old home")
	Hud.show_objectives();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if intro_anim_done:
		camera_2d.position = player_danilo.global_position;

	if show_navigation:
		_update_navigation_trail()
	#if Hud.popup_showing:
		#player_danilo.force_cannot_move = true;
	#else:
		#player_danilo.force_cannot_move = false;

func _ising_run_left() -> void:
	lola_ising_reavealed = true;
	npc_lola_ising.modulate = Color(1, 1, 1, 1) # normal appearance
	npc_lola_ising.direction = Vector2.LEFT
	
func _talk_with_lola_ising () -> void:
	player_danilo.last_direction = Vector2.UP;
	npc_lola_ising.speed = 80;
	await get_tree().create_timer(1).timeout
	DialogueManager.show_dialogue_balloon(A_3S_1, "start")
	player_danilo.force_cannot_move = false;

func _ising_warning_talk() -> void:
	player_danilo.force_cannot_move = true;
	player_danilo.last_direction = Vector2.UP;
	DialogueManager.show_dialogue_balloon(A_3S_1, "lola_warning")
	player_danilo.force_cannot_move = false;
	await DialogueManager.dialogue_ended
	show_navigation = true
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_danilo.current_npc == "karatula":
			player_danilo.last_direction = Vector2.UP;
			Hud.add_popup_image("res://assets/HUD/signage_laruan.png");
			Hud._toggle_popup()
			player_danilo.force_cannot_move = Hud.popup_showing;
			print("interact");
		elif  player_danilo.current_npc == "bahay":
			print("ACT 3 SCENE 1 DONE");
			SaveManager.game_save.current_act = "act_3"
			SaveManager.game_save.current_scene = "scene_1" # badly named I admit. this is for the 'continue' part in main menu
			SaveManager.save_game()
			SignalBus.act_num_scene_num_done.emit("act_3", "scene_1", "res://scenes/game/act_3/scene_2/act_3_scene_2.tscn") # caught in save manager
			ObjectiveManager.complete_objective(1);
			await get_tree().process_frame 
			Hud.hide_objectives();
			Hud.clear_objectives();

func _on_ising_detector_body_entered(body: Node2D) -> void: # ising will run left
	if body.name == "player_danilo":
		player_danilo.force_cannot_move = true;
		ising_collision_shape_2d.call_deferred("set", "disabled", false)
		await get_tree().process_frame
		_ising_run_left();
		ising_detector.queue_free()
		print("ising trigger")

func _on_ising_turn_body_entered(body: Node2D) -> void: # ising  will turn down
	if body.name == "npc_lola_ising":
		npc_lola_ising.direction = Vector2.DOWN

func _on_ising_stop_body_entered(body: Node2D) -> void:
	print("ising show")
	if body.name == "player_danilo" and not lola_ising_reavealed: # ising will peak
		npc_lola_ising.global_position.x = 104.0;
		npc_lola_ising.global_position.y = -68.0;
	if body.name == "npc_lola_ising": # ising will stop running
		npc_lola_ising.direction = Vector2.ZERO
		call_deferred("_talk_with_lola_ising")

func _on_ising_stop_body_exited(body: Node2D) -> void: # ising will hide
	print("ising hide")
	if body.name == "player_danilo" and not lola_ising_reavealed:
		npc_lola_ising.global_position.x = 122.0;
		npc_lola_ising.global_position.y = -68.0;

func _on_ising_warning_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		call_deferred("_ising_warning_talk")
		ising_warning.queue_free()

func _on_karatula_2_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("karatula")
		
func _on_karatula_2_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("karatula")

func _on_echoes_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		DialogueManager.show_dialogue_balloon(A_3S_1, "echoes")
		$interaction_areas/echoes.queue_free()

func _on_bahay_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("bahay");
		

func _on_bahay_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("bahay"); # Replace with function body.
		
 
func _update_navigation_trail() -> void:
	var player_pos = player_danilo.global_position
	var target_pos = navigation_home.global_position
	var distance = player_pos.distance_to(target_pos)

	var desired_num = clamp(int(distance / base_distance), 20, max_lights)

	while lights.size() < desired_num:
		var l = light_scene.instantiate()
		navigation_lights.add_child(l)
		lights.append(l)

	while lights.size() > desired_num:
		lights.pop_back().queue_free()

	for i in range(lights.size()):
		var t = float(i + 1) / (lights.size() + 1)
		var pos = player_pos.lerp(target_pos, t)
		var l = lights[i]
		l.global_position = pos

		if l is PointLight2D:
			l.energy = lerp(2.0, 0.8, t)
			l.energy += sin(Time.get_ticks_msec() / 300.0 + i) * 0.1
		else:
			l.modulate.a = lerp(1.0, 0.3, t)
			l.scale = Vector2.ONE * lerp(1.0, 0.6, t)
