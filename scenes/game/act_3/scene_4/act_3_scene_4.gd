extends Node2D

const SCENE_4_DREAM = preload("uid://cic4mooq5xw0c")
const SCENE_4_HOUSE = preload("uid://2y5djxd1h1rf")
const SCENE_4_HOMETOWN = preload("uid://fck7x2vrgla1")
var A_3S_4: Resource


@onready var locations: Node2D = $locations
@onready var player_danilo: CharacterBody2D = $player_danilo
@onready var camera_2d: Camera2D = $Camera2D

@onready var animated_sprite_2d: AnimatedSprite2D = $player_danilo/AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $player_danilo/CollisionShape2D

@onready var bgm_house: AudioStreamPlayer = $BGM_HOUSE
@onready var bgm_suspense: AudioStreamPlayer = $BGM_SUSPENSE

var current_location: Node2D

var first_switch: bool = true
var can_interact: bool = true

var gino_knocked : bool = false
var theresa_asked: bool = false
var vanesa_asked : bool = false
var jonthan_knocked : bool = false

var inspected_picture_frame : bool = false

var wendy_opened: bool = false
var wendy_reply_shown: bool = false
var chat_open: bool = false

#var asked_neighbors : bool = false

func asked_neighbors () -> bool :
	return gino_knocked and theresa_asked and vanesa_asked and jonthan_knocked

var maps = {
	"house": {
		"name": "danilo_hometown_house",
		"y_sorted_path": "danilo_hometown_house/y-sorted",
		"spawn_points": {
			"door": "spawn_points/door",
			"bed": "spawn_points/bed",
			"bed_beside" : "spawn_points/bed_beside"
		},
		"camera": {
			"type": "fixed",
			"zoom": Vector2(3, 3),
			"position": Vector2(0, 0)
		}
	},

	"hometown": {
		"name": "danilo_hometown",
		"y_sorted_path": "danilo_hometown/y-sorted-objects",
		"spawn_points": {
			"house_door": "spawn_points/door_outside",
		},
		"camera": {
			"type": "follow",
			"zoom": Vector2(3, 3),
			"limits": { "top": -700, "right": 700, "bottom": 600, "left": -720 }
		}
	}
}

var scene_objectives: Array[Dictionary] = [
	{"ID": 1, "text": "Ask neighbors about the incident "},
	{"ID": 2, "text": "Go Back Home"},
]

func _ready() -> void:
	_game_state_flow()
	bgm_house.play()
	FlashlightManager.set_current_scene("act_3", "scene_4")
	FlashlightManager.disable_flashlights()
	_load_dialogue()
	_switch_location(
		SCENE_4_HOUSE,
		"house",
		"bed"
	)
	_intro_sequence()
	
	SignalBus.start_jonathan.connect(_on_start_jonathan)
	SignalBus.last_words.connect(_on_last_words)

	SignalBus.optional_chats_locked = false
	chat_open = false
	SignalBus.chat_opened.connect(_on_chat_opened)
	SignalBus.unknown_sender_unlocked = true
	SignalBus.unknown_sender_label_visible = false
	
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_3/scene_4/a3s4_en.dialogue"
	else:
		path = "res://dialogues/act_3/scene_4/a3s4.dialogue"
	
	A_3S_4 = load(path)
	
func _game_state_flow() -> void:
	# PUT THIS AT THE BEGINNING OF FUNC _READY
	GameState.load_game()
	GameState.current_act = "act_3"
	GameState.current_scene = "scene_4"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()
	
func _on_last_words()->void:
	DialogueManager.show_dialogue_balloon(A_3S_4, "last_statement_1")

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("interact"):
		
		if player_danilo.current_npc == "":
			return
		if not can_interact:
			return
		can_interact = false
		
		match player_danilo.current_npc:
			"door_inside":
				if asked_neighbors():
					can_interact = false
					DialogueManager.show_dialogue_balloon(A_3S_4, "asked_neighbors")
					return
				else:
					can_interact = false
					_switch_location(
						SCENE_4_HOMETOWN,
						"hometown",
						"house_door"
					)
					ObjectiveManager.complete_objective(2)
				
			"karatula":
				Hud.add_popup_image("res://assets/HUD/signage_laruan.png")
				Hud._toggle_popup()
				player_danilo.force_cannot_move = Hud.popup_showing
				can_interact = true
			
			#door_gino,area_vanessa, door_jonathan, door_theresa
			
			"door_gino":
				npc_interactions(gino_knocked, "gino_knock", "gino_knock_again")
				
			"door_theresa":
				SignalBus.start_theresa.emit()
				await get_tree().create_timer(0.5).timeout
				npc_interactions(theresa_asked, "theresa", "theresa_again")
			
			"area_vanessa":
				SignalBus.start_vanesa.emit()
				await get_tree().create_timer(0.5).timeout
				npc_interactions(vanesa_asked, "vanesa", "vanesa_again")
			
			"door_jonathan":
				SignalBus.knocked_jonathan.emit()
				npc_interactions(jonthan_knocked, "jonathan_knock", "jonathan_knock_again")
			
			"home_door":
				if not asked_neighbors():
					can_interact = false
					DialogueManager.show_dialogue_balloon(A_3S_4, "home_door")
				else:
					bgm_house.stop()
					bgm_suspense.play()
					can_interact = false
					_switch_location(
						SCENE_4_HOUSE,
						"house",
						"door"
					)
					SignalBus.asked_neighbors_done = true
					ObjectiveManager.complete_objective(scene_objectives[1]["ID"])
					await get_tree().create_timer(0.4).timeout
					Hud.hide_objectives()
			"picture_frame":
				can_interact = false
				npc_interactions(inspected_picture_frame, "picture_frame", "picture_frame_done")
				
func _check_objectives()->void:
	if asked_neighbors():
		await get_tree().create_timer(1.0).timeout
		DialogueManager.show_dialogue_balloon(A_3S_4, "disapointment")
		ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"])

func npc_interactions(flag: bool, start_first:String, start_again: String)->void:
	can_interact = false
	SignalBus.out_npc.emit("")
	if not flag:
		DialogueManager.show_dialogue_balloon(A_3S_4, start_first)
	else:
		DialogueManager.show_dialogue_balloon(A_3S_4, start_again)

func _switch_location(scene: PackedScene, map_key: String, spawn_point: String) -> void:
	if first_switch:
		first_switch = false
	else:
		TransitionFade.transition()
		await SignalBus.on_transition_finished

	# Always remove player first (avoid "already has a parent")
	if player_danilo.get_parent():
		player_danilo.get_parent().remove_child(player_danilo)

	# Remove previous map
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()
		await get_tree().process_frame

	# Load and add new map
	current_location = scene.instantiate()
	locations.add_child(current_location)

	var map_data = maps[map_key]
	var y_sorted_path = map_data["y_sorted_path"]
	var y_sorted_node = current_location.get_node_or_null(y_sorted_path)
	if not y_sorted_node:
		push_error("Missing y-sorted node in map: " + map_key)
		return

	# Get spawn node (root-relative, not doubled)
	var spawn_relative_path = "%s/%s" % [y_sorted_path, map_data["spawn_points"].get(spawn_point, "")]
	var spawn_location = current_location.get_node_or_null(spawn_relative_path)
	if not spawn_location:
		push_warning("Spawn point '%s' not found in map '%s'" % [spawn_point, map_key])
		return

	# Add player into correct y-sorted node
	y_sorted_node.add_child(player_danilo)
	player_danilo.global_position = spawn_location.global_position

	# Apply camera rules
	_set_camera(map_key)

	await get_tree().process_frame
	can_interact = true

func _set_camera(map_key: String) -> void:
	var cam_data = maps[map_key]["camera"]
	camera_2d.zoom = cam_data.get("zoom", Vector2(3, 3))

	if cam_data["type"] == "fixed":
		if camera_2d.get_parent() != self:
			camera_2d.get_parent().remove_child(camera_2d)
			add_child(camera_2d)
		camera_2d.position = cam_data.get("position", Vector2.ZERO)

	elif cam_data["type"] == "follow":
		if camera_2d.get_parent() != player_danilo:
			camera_2d.get_parent().remove_child(camera_2d)
			player_danilo.add_child(camera_2d)
			camera_2d.position = Vector2.ZERO
		var limits = cam_data.get("limits", null)
		if limits:
			_set_camera_limits(limits.top, limits.right, limits.bottom, limits.left)

	camera_2d.make_current()

func _set_camera_limits(top: int = 0, right: int = 0, bottom: int = 0, left: int = 0) -> void:
	camera_2d.limit_top = top
	camera_2d.limit_right = right
	camera_2d.limit_bottom = bottom
	camera_2d.limit_left = left

func _intro_sequence()->void:
	player_danilo.force_cannot_move = true
	player_danilo.animation_locked = true
	collision_shape_2d.disabled = true
	animated_sprite_2d.play("sleeping_hometown")
	await get_tree().create_timer(0.5).timeout
	DialogueManager.show_dialogue_balloon(A_3S_4, "woke_up")

func _get_out_of_bed_take_meds () -> void:
	SaveManager.took_meds("act_3_scene_4")
	player_danilo.last_direction = Vector2.DOWN
	
	
	await get_tree().create_timer(1.0).timeout
	animated_sprite_2d.play("idle_down")
	
	player_danilo.global_position = current_location.get_node("danilo_hometown_house/y-sorted/spawn_points/bed_beside").global_position
	# here logic for recording meds taken
	
	animated_sprite_2d.play("taking_meds_sit_right")
	await animated_sprite_2d.animation_finished
	
	await get_tree().create_timer(1.0).timeout
	animated_sprite_2d.play("idle_right")
	
	await get_tree().create_timer(1.0).timeout
	animated_sprite_2d.play("idle_up")
	
	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue_balloon(A_3S_4, "window_is_open")
	
	await get_tree().create_timer(0.5).timeout
	ObjectiveManager.add_progress_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"], 4)
	Hud.show_objectives()
	
	player_danilo.force_cannot_move = false
	player_danilo.animation_locked = false
	collision_shape_2d.disabled = false
	
func _get_out_of_bed_check_phone () -> void:
	SaveManager.missed_meds("act_3_scene_4")
	player_danilo.last_direction = Vector2.DOWN
	
	
	await get_tree().create_timer(1.0).timeout
	animated_sprite_2d.play("idle_down")
	
	player_danilo.global_position = current_location.get_node("danilo_hometown_house/y-sorted/spawn_points/bed_beside").global_position
	# here logic for recording meds taken
	
	await get_tree().create_timer(1.0).timeout
	animated_sprite_2d.play("idle_right")
	
func _notice_open_window () -> void:
	player_danilo.last_direction = Vector2.RIGHT
	
	await get_tree().create_timer(1.0).timeout
	animated_sprite_2d.play("idle_up")
	
	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue_balloon(A_3S_4, "window_is_open")
	
	await get_tree().create_timer(0.5).timeout
	ObjectiveManager.add_progress_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"], 4)
	Hud.show_objectives()
	
	player_danilo.force_cannot_move = false
	player_danilo.animation_locked = false
	collision_shape_2d.disabled = false
	
func _on_chat_opened(chat_name: String) -> void:
	if chat_name == "wendy" and not wendy_opened:
		wendy_opened = true
		ObjectiveManager.complete_objective(scene_objectives[0]["ID"])
		DialogueManager.show_dialogue_balloon(A_3S_4, "chat_of_wendy")
	
func _on_start_jonathan() -> void:
	DialogueManager.show_dialogue_balloon(A_3S_4, "jonathan")

func _act_3_scene_4_done() -> void:
	SaveManager.game_save.current_act = "act_4"
	SaveManager.game_save.current_scene = "scene_1"
	SaveManager.save_game()
	GameState.save_game()
	SignalBus.act_num_scene_num_done.emit("act_3", "scene_4", "res://scenes/game/act_4_title_scene.tscn") # caught in save manager
	Hud.clear_objectives();
