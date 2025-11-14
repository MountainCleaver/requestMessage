extends Node2D

const SCENE_3_TOWN_CENTER = preload("uid://cqk500i2neu4t")
const SCENE_3_DANILO_HOUSE = preload("uid://c7ufelds3m81i")
const SCENE_3_DRUGSTORE = preload("uid://7wtc2deofp0e")
const SCENE_3_DANILO_HOMETOWN = preload("uid://fgxe57bsbw2l")

const SQUARE_BREATHING_MINI_GAME = preload("uid://e4djirwvv7iy")
const SCHED_ICON = preload("uid://d1ye4ylli8nca")

@onready var player_danilo: CharacterBody2D = $player_danilo

@onready var locations: Node2D = $locations
@onready var camera_2d: Camera2D = $player_danilo/Camera2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var danilo_collision_shape_2d: CollisionShape2D = $player_danilo/CollisionShape2D
@onready var danilo_animated_sprite_2d: AnimatedSprite2D = $player_danilo/AnimatedSprite2D

# --- AUDIO NODES ---
@onready var sfx_sqbr: AudioStreamPlayer = $SFXsqbr
@onready var bgm_home: AudioStreamPlayer = $BGMHome
@onready var sfx_paranoia: AudioStreamPlayer = $SFXParanoia


var _debounce_timer: SceneTreeTimer = null
const DEBOUNCE_DELAY := 0.5 

signal restless_diag_one_done
signal start_mini_game
signal mini_game_done
signal intro_sequence_done
signal went_outside_find_tricycle

var current_location: Node = null
var mini_game : Node2D = null
var player_instance: Node2D = null

var first_mini_game : bool = true
var second_mini_game : bool = false
var in_dialogue : bool = false

var bought_meds : bool = false

var first_switch : bool = true

var chat_exit_disabled : bool = false

var can_interact : bool = true # for guarding against spamming "E" when an interaction triggers a dialog

var mini_game_completed: bool = false

var already_triggered_paranoia := false

var A_3S_3: Resource

var maps = {
	
	"house" : {
		"name" : "danilo_hometown_house",
		"spawn_points" : {
			"middle"  : "middle_point",
			"door"    : "door_point",
			"bed"     : "bed_point",
			"sq_house" : "sq_point"
		}
	},
	
	"town_center" : {
		"name" : "hometown_town_center",
		"spawn_points" : {
			"drug_store" : "drug_store_door_point",
			"middle" : "town_center_middle"
		},
		"camera_limits" : {
			"top": -460, 
			"right": 715, 
			"bottom": 600, 
			"left": -733
		}
	},
	"drugstore" : {
		"name" : "drugstore",
		"spawn_points" : {
			"door" : "drugstore_door_point"
		}
	},
	"hometown" : {
		"name" : "danilo_hometown",
		"spawn_points" : {
			"house_door" : "house_door_step_point",
			"tri_off" : "tricycle_off_point",
			"check_outside" : "check_out_outside"
		},
		"camera_limits": {
			"top": -700, 
			"right": 700, 
			"bottom": 600, 
			"left": -720
			}
	}
}
@onready var sfx_meds: AudioStreamPlayer = $SFX_MEDS
signal objective_one_done

var done_objective_one : bool = false
var done_objective_three: bool = false
var disable_nav_for_next_switch: bool = false
enum player_where {INSIDE, OUTSIDE}

var scene_objectives : Array[Dictionary] = [
	{"ID": 1, "text" : "Go outside"},
	{"ID": 2, "text" : "[shake]Check the Photo Again[/shake]"},
	{"ID": 3, "text" : "Ride a Tricycle to Bayan"},
	{"ID": 4, "text": "Find a Drugstore"},
	{"ID" : 5, "text" : "Go Back Home"},
	{"ID" : 6, "text" : "Go to bed and try to calm yourself"},
]

var moral_choice : String

# NAVIGATION TRAIL
var navigation_home: Node2D = null
var navigation_lights: Node2D = null
var lights: Array = []
var show_navigation: bool = false
var max_lights := 100
var base_distance := 200.0
var light_scene := preload("res://assets/tilesets/nav_light.tscn") 

func _ready() -> void:
	FlashlightManager.set_current_scene("act_3", "scene_3")
	FlashlightManager.disable_flashlights()
	_load_dialogue()
	Hud.reset_phone_dont_show()
	_game_state_flow()
	SignalBus.unknown_sender_unlocked = true
	SignalBus.mini_game_done.connect(_on_mini_game_done)
	SignalBus.chat_opened.connect(_on_chat_opened)
	SignalBus.area_one_entered.connect(_on_area_one_entered)
	SignalBus.second_house_exit.connect(_on_second_house_exit)
	SignalBus.mini_game_done.connect(_on_mini_game_done)
	objective_one_done.connect(_on_objective_one_done)
	restless_diag_one_done.connect(_on_restless_diag_one_done)
	went_outside_find_tricycle.connect(_on_went_outside_find_tricycle)
	moral_choice = SaveManager.get_moral_choice("act_3_scene_2")
	_intro_sequence(moral_choice)
	_put_tension_effect()
	start_mini_game.connect(_start_mini_game)
	intro_sequence_done.connect(_on_intro_sequence_done)
   
	bgm_home.stop()   
	 
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_3/scene_3/a3s3_en.dialogue"
	else:
		path = "res://dialogues/act_3/scene_3/a3s3.dialogue"
	
	A_3S_3 = load(path)
	
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if not can_interact:
		return
	
	# lock right away

	match player_danilo.current_npc:
		"door_inside":
			if not bought_meds:
				can_interact = false
				_switch_location(
					SCENE_3_DANILO_HOMETOWN,
					maps["hometown"]["name"],
					maps["hometown"]["spawn_points"]["house_door"]
				)
				# Emit objectives/events only if not done yet
				if not done_objective_one:
					done_objective_one = true
					objective_one_done.emit()

				if not done_objective_three:
					went_outside_find_tricycle.emit()
			else:
				can_interact = false
				if not second_mini_game or not mini_game_completed:
					DialogueManager.show_dialogue_balloon(A_3S_3, "rushed_home")

		"door_outside":
			can_interact = false
			if not bought_meds:
				SignalBus.out_npc.emit("door_outside")
				DialogueManager.show_dialogue_balloon(A_3S_3, "not_yet_bought_meds")
			else:
					_switch_location(
						SCENE_3_DANILO_HOUSE,
						maps["house"]["name"],
						maps["house"]["spawn_points"]["door"]
					)
					ObjectiveManager.complete_objective(scene_objectives[4]["ID"])
					await get_tree().create_timer(0.5).timeout
					Hud.clear_objectives()
					ObjectiveManager.add_objective(scene_objectives[5]["ID"], scene_objectives[5]["text"])
					player_danilo.SPEED = 80.0
		"tricycle_hometown":
			can_interact = false
			if not bought_meds:
				SignalBus.out_npc.emit("tricycle_hometown")
				DialogueManager.show_dialogue_balloon(A_3S_3, "tricycle_start")
				#_switch_location(
					#SCENE_3_TOWN_CENTER,
					#maps["town_center"]["name"],
					#maps["town_center"]["spawn_points"]["middle"]
				#)
				ObjectiveManager.complete_objective(scene_objectives[2]["ID"])
			else:
				SignalBus.out_npc.emit("tricycle_hometown")
				DialogueManager.show_dialogue_balloon(A_3S_3, "tricycle_start_bought")
				
		"tricycle_town_center":
			can_interact = false
			if not bought_meds:
				SignalBus.out_npc.emit("tricycle_town_center")
				DialogueManager.show_dialogue_balloon(A_3S_3, "not_yet_bought_meds")
			else:
				#ObjectiveManager.complete_objective(scene_objectives[4]["ID"])
				_clear_navigation_trail()
				_switch_location(
					SCENE_3_DANILO_HOMETOWN,
					maps["hometown"]["name"],
					maps["hometown"]["spawn_points"]["tri_off"]
				)

		"drugstore_door_outside":
			can_interact = false
			ObjectiveManager.complete_objective(scene_objectives[3]["ID"])
			if not bought_meds:
				_switch_location(
					SCENE_3_DRUGSTORE,
					maps["drugstore"]["name"],
					maps["drugstore"]["spawn_points"]["door"]
				)
			else:
				_clear_navigation_trail()
				DialogueManager.show_dialogue_balloon(A_3S_3, "alreay_bought_meds")

		"karatula":
			Hud.add_popup_image("res://assets/HUD/signage_laruan.png")
			Hud._toggle_popup()
			player_danilo.force_cannot_move = Hud.popup_showing

		"drugstore_door_inside":
			can_interact = false
			if not bought_meds:
				SignalBus.out_npc.emit("drugstore_door_inside")
				DialogueManager.show_dialogue_balloon(A_3S_3, "not_yet_bought_meds")
				_clear_navigation_trail()
			else:
				disable_nav_for_next_switch = true
				_switch_location(
					SCENE_3_TOWN_CENTER,
					maps["town_center"]["name"],
					maps["town_center"]["spawn_points"]["drug_store"]
				)
				
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				show_navigation = false
				_clear_navigation_trail()
				DialogueManager.show_dialogue_balloon(A_3S_3, "go_home")
				await SignalBus.on_transition_finished
				Hud.clear_objectives()
				ObjectiveManager.add_objective(scene_objectives[4]["ID"], scene_objectives[4]["text"])

		"pharmacist":
			can_interact = false
			SignalBus.out_npc.emit("pharmacist")
			_clear_navigation_trail()
			if not bought_meds:
				DialogueManager.show_dialogue_balloon(A_3S_3, "drugstore_clerk")
				#ObjectiveManager.complete_objective(scene_objectives[3]["ID"])
			else:
				DialogueManager.show_dialogue_balloon(A_3S_3, "drugstore_clerk_bought")
		"bed":
			can_interact = false
			if second_mini_game and mini_game_completed:
				danilo_collision_shape_2d.disabled = true
				player_danilo.animation_locked = true
				player_danilo.force_cannot_move = true
				player_danilo.global_position = Vector2(-88.0, 8.0)
				danilo_animated_sprite_2d.play("sleep_only_hometown")
				await get_tree().create_timer(1.0).timeout
				_act_3_scene_3_done()
			else:
				second_mini_game = true
				danilo_collision_shape_2d.disabled = true
				player_danilo.animation_locked = true
				player_danilo.force_cannot_move = true
				danilo_animated_sprite_2d.play("sitting")

				var spawn_location = current_location.get_node_or_null("danilo_hometown_house/y-sorted/spawn_points/bed_point")
				if spawn_location:
					player_danilo.velocity = Vector2.ZERO
					player_danilo.global_position = spawn_location.global_position
				else:
					push_error("Bed spawn point not found!")

				await get_tree().process_frame
				if spawn_location:
					player_danilo.global_position = spawn_location.global_position

				SignalBus.sat_on_bed.emit()
				start_mini_game.emit()
				ObjectiveManager.complete_objective(6)
				Hud.hide_objectives()
				Hud.clear_objectives()


func _game_state_flow() -> void:
	# PUT THIS AT THE BEGINNING OF FUNC _READY
	GameState.load_game()
	GameState.current_act = "act_3"
	GameState.current_scene = "scene_3"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()

func _switch_location(scene: PackedScene,map_name: String, spawn_point: String) -> void:
	_clear_navigation_trail()
	if first_switch:
		first_switch = false
	else:
		TransitionFade.transition()
		await SignalBus.on_transition_finished
	# Remove previous location
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	# Instance and add new map 
	current_location = scene.instantiate()
	locations.add_child(current_location)
	
	# === ADJUST PLAYER SPEED BASED ON MAP ===
	if map_name == maps["house"]["name"]:
		player_danilo.SPEED = 80.0
		player_danilo.RUNNING_SPEED = 200.0
	elif map_name == maps["hometown"]["name"]:
		if already_triggered_paranoia:
			player_danilo.SPEED = 340.0
			player_danilo.RUNNING_SPEED = 340.0
		else:
			player_danilo.SPEED = 80.0
			player_danilo.RUNNING_SPEED = 200.0
	elif map_name == maps["town_center"]["name"]:
		player_danilo.SPEED = 80.0
		player_danilo.RUNNING_SPEED = 200.0
	elif map_name == maps["drugstore"]["name"]:
		player_danilo.SPEED = 80.0
		player_danilo.RUNNING_SPEED = 200.0
	# ========================================
	if map_name == maps["drugstore"]["name"]:
		show_navigation = false
		_clear_navigation_trail()
		
		
	# Get y-sorted node
	var y_sorted_node
	if map_name == "danilo_hometown":
		y_sorted_node = current_location.get_node_or_null("%s/y-sorted-objects" % map_name)
	else:
		y_sorted_node = current_location.get_node_or_null("%s/y-sorted" % map_name)
		
	if not y_sorted_node:
		push_error("Missing y-sorted node in map")
		return

	# Find spawn point      sample path: danilo_hometown_house/y-sorted/spawn_points/middle_point
	var spawn_location
	if map_name == "danilo_hometown":
		spawn_location = current_location.get_node_or_null("%s/y-sorted-objects/spawn_points/%s" % [map_name, spawn_point])
	else:
		spawn_location = current_location.get_node_or_null("%s/y-sorted/spawn_points/%s" % [map_name, spawn_point])
	if not spawn_location:
		push_warning("Spawn point '%s' not found in map" % spawn_point)
		return

	# Reparent existing player
	if player_danilo.get_parent() != null:
		player_danilo.get_parent().remove_child(player_danilo)

	y_sorted_node.add_child(player_danilo)

	player_danilo.global_position = spawn_location.global_position
	_set_camera(map_name)
	
	#print(spawn_location)
	await get_tree().process_frame
	can_interact = true

func _intro_sequence (moral_choice: String) -> void:
	match moral_choice:
		"restless":
			resltess_choice_consequence()
			
		"relief":
			relief_choice_consequence()

func relief_choice_consequence()->void:
	first_mini_game = true
	DialogueManager.show_dialogue_balloon(A_3S_3, "start_relief")
	danilo_collision_shape_2d.disabled = true
	player_danilo.animation_locked = true
	player_danilo.force_cannot_move = true
	danilo_animated_sprite_2d.play("sitting")
	_switch_location(
		SCENE_3_DANILO_HOUSE,
		maps["house"]["name"],
		maps["house"]["spawn_points"]["bed"]
	)

func resltess_choice_consequence() -> void:
	first_mini_game = false
	second_mini_game = true
	player_danilo.force_cannot_move = true
	ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"], Color.RED)
	Hud.show_objectives()
	DialogueManager.show_dialogue_balloon(A_3S_3, "start_restless")
	_switch_location(
		SCENE_3_DANILO_HOUSE,
		maps["house"]["name"],
		maps["house"]["spawn_points"]["middle"]
	)

func _put_tension_effect()->void:
	animation_player.play("tensioning")

func _remove_tension_effect()->void:
	animation_player.play("tension_out")

func _start_mini_game(map_name: String = maps["house"]["name"] , spawn_point: String = maps["house"]["spawn_points"]["sq_house"])->void:
	sfx_sqbr.play()
	bgm_home.stop()
	sfx_paranoia.stop()
	var target_pos = Vector2(player_danilo.global_position.x + 30, camera_2d.position.y)
	_tween_camera_to(target_pos, 6, 0.2)
	var sq_mg = SQUARE_BREATHING_MINI_GAME.instantiate()
	mini_game = sq_mg
	
	var spawn_loc = current_location.get_node_or_null("%s/y-sorted/spawn_points/%s" % [map_name, spawn_point])
	
	if not spawn_loc:
		push_warning("Spawn point '%s' not found in map" % spawn_point)
		return
	
	current_location.add_child(sq_mg)
	
	danilo_animated_sprite_2d.play("sq_sit_right")

func _on_mini_game_done()->void:
	sfx_sqbr.stop()      # Stop SFX
	bgm_home.play()      # Play BGM!
	if first_mini_game:
		mini_game.queue_free()
		_tween_camera_to(Vector2.ZERO, 3.0)
		danilo_collision_shape_2d.disabled = false
		player_danilo.animation_locked = false
		danilo_animated_sprite_2d.play("idle_down")
		_remove_tension_effect()
		DialogueManager.show_dialogue_balloon(A_3S_3, "buy_meds_restless")
		intro_sequence_done.emit()
		player_danilo.force_cannot_move = false
		first_mini_game = false
	elif second_mini_game:
		mini_game.queue_free()
		_tween_camera_to(Vector2.ZERO, 3.0)
		_remove_tension_effect()
		add_notification(SCHED_ICON, "Reminder", "Take Medication")
		await get_tree().create_timer(0.5).timeout
		Hud.phone_intro("03:00", "PM")
		DialogueManager.show_dialogue_balloon(A_3S_3, "reminder")
		mini_game_done.emit()
		mini_game_completed = true 

func _on_intro_sequence_done() -> void:
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	second_mini_game = true
	if moral_choice == "relief":
		Hud.show_objectives()
	
func play_taking_meds()->void:
	sfx_meds.play()
	danilo_animated_sprite_2d.play("taking_meds_sit_right")
	await danilo_animated_sprite_2d.animation_finished
	danilo_animated_sprite_2d.play("sitting")
	
	player_danilo.global_position = Vector2(-88.0, 8.0)
	danilo_animated_sprite_2d.play("sleep_only_hometown")
	await get_tree().create_timer(1.0).timeout
	_act_3_scene_3_done()
	print("scene finished")

# CAMERA HELPERS ===========================================================================================================================
func _set_camera(map_name: String) -> void:
	if map_name == maps["house"]["name"] or map_name == maps["drugstore"]["name"]:
		# Detach the camera from player for fixed view
		if camera_2d.get_parent() != self:
			camera_2d.get_parent().remove_child(camera_2d)
			add_child(camera_2d)
		camera_2d.position = Vector2(0, 0)
		camera_2d.zoom = Vector2(4.0, 4.0)
		camera_2d.make_current()

	elif map_name == maps["hometown"]["name"]:
		if camera_2d.get_parent() != player_danilo:
			camera_2d.get_parent().remove_child(camera_2d)
			player_danilo.add_child(camera_2d)
			camera_2d.position = Vector2.ZERO
		camera_2d.zoom = Vector2(4.0, 4.0)

		var cam_limits = maps["hometown"].get("camera_limits", null)
		if cam_limits:
			_set_camera_limits(
				cam_limits.top,
				cam_limits.right,
				cam_limits.bottom,
				cam_limits.left
			)
			camera_2d.make_current()

	elif map_name == maps["town_center"]["name"]:
		print("in town center")
		navigation_lights = current_location.get_node_or_null("navigation_lights")
		if navigation_lights:
			navigation_home = navigation_lights.get_node_or_null("navigation_home")
			if navigation_home and not disable_nav_for_next_switch:
				lights.clear()
				show_navigation = true
		disable_nav_for_next_switch = false

				
		if camera_2d.get_parent() != player_danilo:
			camera_2d.get_parent().remove_child(camera_2d)
			player_danilo.add_child(camera_2d)
			camera_2d.position = Vector2.ZERO
		camera_2d.zoom = Vector2(4.0, 4.0)

		var cam_limits = maps["town_center"].get("camera_limits", null)
		if cam_limits:
			_set_camera_limits(
				cam_limits.top,
				cam_limits.right,
				cam_limits.bottom,
				cam_limits.left
			)
		camera_2d.make_current()

func _set_camera_limits(top: int, right: int, bottom: int, left: int)->void:
	camera_2d.limit_top = top
	camera_2d.limit_right = right
	camera_2d.limit_bottom = bottom
	camera_2d.limit_left = left

func _tween_camera_to(pos: Vector2, zoom: float, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(camera_2d, "position", pos, duration)
	tween.tween_property(camera_2d, "zoom", Vector2(zoom, zoom), duration)

func _on_objective_one_done()-> void:
	ObjectiveManager.complete_objective(scene_objectives[0]["ID"])

func _on_chat_opened(chat_name: String) ->void:
	if chat_name == "unknown_sender":
		ObjectiveManager.complete_objective(scene_objectives[1]["ID"])
		DialogueManager.show_dialogue_balloon(A_3S_3, "start_restless_2")

func _on_restless_diag_one_done () -> void:
	Hud.reset_phone_state("02:03", "PM")

func _on_went_outside_find_tricycle () -> void:
	ObjectiveManager.add_objective(scene_objectives[2]["ID"], scene_objectives[2]["text"])

func _on_area_one_entered() -> void:
	if already_triggered_paranoia:
		return
	already_triggered_paranoia = true

	await get_tree().create_timer(0.2).timeout
	animation_player.play("tensioning")
	can_interact = false
	
	DialogueManager.show_dialogue_balloon(A_3S_3, "paranoia")
	player_danilo.SPEED = 280.0
	sfx_paranoia.play()
	bgm_home.stop()
	
func add_notification(image: Texture2D, app_name: String, notif_content: String) -> void:
	Hud.get_node("Control/phone/MarginContainer/lock_screen").add_notification(image, app_name, notif_content)
	
func _on_second_house_exit() -> void:
	var spawn_location = current_location.get_node_or_null("danilo_hometown_house/y-sorted/spawn_points/out_bed_point")
	if not spawn_location:
		push_error("Out bed spawn point not found!")
		return

	await get_tree().process_frame
	await get_tree().process_frame
	
	player_danilo.global_position = spawn_location.global_position
	danilo_collision_shape_2d.disabled = false
	player_danilo.force_cannot_move = false
	player_danilo.animation_locked = false
	danilo_animated_sprite_2d.play("idle_up")

	second_mini_game = true
	mini_game_completed = true 

	await DialogueManager.dialogue_ended
	await get_tree().create_timer(0.5).timeout
	
	can_interact = false

	_switch_location(
		SCENE_3_DANILO_HOMETOWN,
		maps["hometown"]["name"],
		maps["hometown"]["spawn_points"]["check_outside"]
	)
	await get_tree().process_frame
	await get_tree().process_frame
	
	await _play_look_around_sequence()

	DialogueManager.show_dialogue_balloon(A_3S_3, "check_outside")
	await DialogueManager.dialogue_ended

	await get_tree().create_timer(0.5).timeout
	
	_switch_location(
		SCENE_3_DANILO_HOUSE,
		maps["house"]["name"],
		maps["house"]["spawn_points"]["door"]
	)
	await get_tree().process_frame
	await get_tree().process_frame
	

	danilo_collision_shape_2d.disabled = false
	player_danilo.force_cannot_move = false
	player_danilo.animation_locked = false

	can_interact = true

func _play_look_around_sequence() -> void:
	player_danilo.force_cannot_move = true
	danilo_collision_shape_2d.disabled = true
	var directions = ["idle_up", "idle_left", "idle_right", "idle_down"]

	for dir in directions:
		danilo_animated_sprite_2d.play(dir)
		await get_tree().create_timer(0.8).timeout

	danilo_animated_sprite_2d.play("idle_down")


func _process(delta: float) -> void:
	if show_navigation and player_danilo and navigation_home:
		_update_navigation_trail()
	
func _update_navigation_trail() -> void:
	var player_pos = player_danilo.global_position
	var target_pos = navigation_home.global_position
	var distance = player_pos.distance_to(target_pos)

	var desired_num = clamp(int(distance / base_distance), 30, max_lights)

	# Add lights
	while lights.size() < desired_num:
		var l = light_scene.instantiate()
		navigation_lights.add_child(l)
		lights.append(l)

	# Remove excess lights
	while lights.size() > desired_num:
		lights.pop_back().queue_free()

	# Update positions
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
	
func _act_3_scene_3_done() -> void:
	if Hud.phone_showing:
		Hud.phone_outro()
	SaveManager.game_save.current_act = "act_3"
	SaveManager.game_save.current_scene = "scene_3"
	SaveManager.save_game()
	SignalBus.act_num_scene_num_done.emit("act_3", "scene_3", "res://scenes/game/act_3/scene_4/act_3_scene_4.tscn")
	ObjectiveManager.empty_objectives()
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
