extends Node2D

@onready var player_danilo: CharacterBody2D = $player_danilo
var A_1S_2: Resource

# Navigation lights
@onready var navigation_home: Marker2D = $navigation_lights/navigation_home
@onready var navigation_lights: Node2D = $navigation_lights
var lights: Array = []
var show_navigation := false
var max_lights := 100
var base_distance := 200.0
var light_scene := preload("res://assets/tilesets/nav_light.tscn") 

func _ready() -> void:
	FlashlightManager.set_current_scene("act_1", "scene_2")
	FlashlightManager.disable_flashlights()
	_load_dialogue()
	show_navigation = true
	ObjectiveManager.add_objective(1, "Ride a Jeepney to Rizal Park")
	Hud.show_objectives()
	if BgmManager:
		BgmManager.stop_music()

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_1/scene_2/a1s2_en.dialogue"
	else:
		path = "res://dialogues/act_1/scene_2/a1s2.dialogue"
	
	A_1S_2 = load(path)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_danilo.can_interact:
		DialogueManager.show_dialogue_balloon(A_1S_2, "start")

func _on_area_2d_body_entered(body: Node2D) -> void:
	player_danilo.show_tip("jeep")
	SignalBus.in_jeep_area.emit()
	_clear_navigation_trail() 
	
func _on_area_2d_body_exited(body: Node2D) -> void:
	player_danilo.hide_tip("jeep")
	SignalBus.out_jeep_area.emit()


func _process(_delta: float) -> void:
	if show_navigation:
		_update_navigation_trail()

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

func _clear_navigation_trail() -> void:
	show_navigation = false
	if navigation_lights and navigation_lights.is_inside_tree():
		for l in navigation_lights.get_children():
			l.queue_free()
	lights.clear()
	
func bogok (res : String) -> void:
	print(res);
