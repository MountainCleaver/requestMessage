extends Node2D

const SCENE_3_TOWN_CENTER = preload("uid://cqk500i2neu4t")
const SCENE_3_DANILO_HOUSE = preload("uid://c7ufelds3m81i")
const SCENE_3_DRUGSTORE = preload("uid://7wtc2deofp0e")
const SCENE_3_DANILO_HOMETOWN = preload("uid://fgxe57bsbw2l")

const SQUARE_BREATHING_MINI_GAME = preload("uid://e4djirwvv7iy")

@onready var player_danilo: CharacterBody2D = $player_danilo

@onready var locations: Node2D = $locations
@onready var camera_2d: Camera2D = $player_danilo/Camera2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var danilo_collision_shape_2d: CollisionShape2D = $player_danilo/CollisionShape2D
@onready var danilo_animated_sprite_2d: AnimatedSprite2D = $player_danilo/AnimatedSprite2D

signal restless_diag_one_done
signal start_mini_game
signal mini_game_done
signal intro_sequence_done
signal went_outside_find_tricycle

var current_location: Node = null
var mini_game : Node2D = null
var player_instance: Node2D = null

var bought_meds : bool = false

var first_switch : bool = true

var chat_exit_disabled : bool = false

var can_interact : bool = true # for guarding against spamming "E" when an interaction triggers a dialog

const A_3S_3 = preload("uid://befctg2rwc1x7")

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
			"house_door" : "house_door_step_point"
		},
		"camera_limits": {
			"top": -700, 
			"right": 700, 
			"bottom": 600, 
			"left": -720
			}
	}
}

signal objective_one_done

var done_objective_one : bool = false
var done_objective_three: bool = false

enum player_where {INSIDE, OUTSIDE}

var scene_objectives : Array[Dictionary] = [
	{"ID": 1, "text" : "Go outside"},
	{"ID": 2, "text" : "[shake]Check the Photo Again[/shake]"},
	{"ID": 3, "text" : "Ride a Tricycle to Bayan"},
]


var moral_choice : String


func _ready() -> void:

	#camera_2d.position_smoothing_enabled = true
	#camera_2d.position_smoothing_speed = 10.0
	
	_game_state_flow()
	SignalBus.unknown_sender_unlocked = true
	SignalBus.mini_game_done.connect(_on_mini_game_done)
	SignalBus.chat_opened.connect(_on_chat_opened)
	
	objective_one_done.connect(_on_objective_one_done)
	restless_diag_one_done.connect(_on_restless_diag_one_done)
	went_outside_find_tricycle.connect(_on_went_outside_find_tricycle)
	
	moral_choice = SaveManager.get_moral_choice("act_3_scene_2")
	_intro_sequence(moral_choice)
	
	_put_tension_effect()
	
	start_mini_game.connect(_start_mini_game)
	intro_sequence_done.connect(_on_intro_sequence_done)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_interact:
		can_interact = false 

		match player_danilo.current_npc:
			"door_inside":
				_switch_location(
					SCENE_3_DANILO_HOMETOWN,
					maps["hometown"]["name"],
					maps["hometown"]["spawn_points"]["house_door"]
				)
				
				if not done_objective_one:
					done_objective_one = true
					objective_one_done.emit()
					
				if not done_objective_three:
					went_outside_find_tricycle.emit()
				
			
				await SignalBus.on_transition_finished
				can_interact = true 

			"tricycle_hometown":
				if not bought_meds:
					DialogueManager.show_dialogue_balloon(A_3S_3, "tricycle_start")
					_switch_location(
						SCENE_3_TOWN_CENTER,
						maps["town_center"]["name"],
						maps["town_center"]["spawn_points"]["middle"]
					)
				else:
					DialogueManager.show_dialogue_balloon(A_3S_3, "tricycle_start_bought")
				await SignalBus.on_transition_finished
				can_interact = true  

			"karatula":
				Hud.add_popup_image("res://assets/HUD/signage_laruan.png")
				Hud._toggle_popup()
				player_danilo.force_cannot_move = Hud.popup_showing


func _game_state_flow() -> void:
	# PUT THIS AT THE BEGINNING OF FUNC _READY
	GameState.load_game()
	GameState.current_act = "act_3"
	GameState.current_scene = "scene_3"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()

func _switch_location(scene: PackedScene,map_name: String, spawn_point: String) -> void:
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

func _intro_sequence (moral_choice: String) -> void:
	match moral_choice:
		"restless":
			resltess_choice_consequence()
			
		"relief":
			relief_choice_consequence()

func relief_choice_consequence()->void:
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

#func _prevent_chat_exit_while_dialoging () -> void:
	#if not chat_exit_disabled:
		#Hud.get_node("Control/phone/MarginContainer/app_chat_convo/screen/Panel/EXIT").disabled = true
		#chat_exit_disabled = true
	#else:
		#Hud.get_node("Control/phone/MarginContainer/app_chat_convo/screen/Panel/EXIT").disabled = false
		#chat_exit_disabled = false

#func _clean_phone() ->void:
	#var phone_margin_container = Hud.get_node("Control/phone/MarginContainer")
	#var nodes = phone_margin_container.get_children()
	#
	#for node in nodes:
		#if node.name != "lock_screen":
			#node.queue_free()

func _start_mini_game(map_name: String = maps["house"]["name"] , spawn_point: String = maps["house"]["spawn_points"]["sq_house"])->void:
	
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
	mini_game.queue_free()
	_tween_camera_to(Vector2.ZERO, 3.0)
	danilo_collision_shape_2d.disabled = false
	player_danilo.animation_locked = false
	danilo_animated_sprite_2d.play("idle_down")
	_remove_tension_effect()
	DialogueManager.show_dialogue_balloon(A_3S_3, "buy_meds_restless")
	intro_sequence_done.emit()
	player_danilo.force_cannot_move = false

func _on_intro_sequence_done() -> void:
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	if moral_choice == "relief":
		Hud.show_objectives()
	


# CAMERA HELPERS ===========================================================================================================================
func _set_camera(map_name: String) -> void:
	if map_name == maps["house"]["name"]:
		# Detach the camera from player for fixed view
		if camera_2d.get_parent() != self:
			camera_2d.get_parent().remove_child(camera_2d)
			add_child(camera_2d)
		camera_2d.position = Vector2(0, 0)
		camera_2d.zoom = Vector2(3.0, 3.0)
		camera_2d.make_current()

	elif map_name == maps["hometown"]["name"]:
		if camera_2d.get_parent() != player_danilo:
			camera_2d.get_parent().remove_child(camera_2d)
			player_danilo.add_child(camera_2d)
			camera_2d.position = Vector2.ZERO
		camera_2d.zoom = Vector2(3.0, 3.0)

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
		if camera_2d.get_parent() != player_danilo:
			camera_2d.get_parent().remove_child(camera_2d)
			player_danilo.add_child(camera_2d)
			camera_2d.position = Vector2.ZERO
		camera_2d.zoom = Vector2(3.0, 3.0)

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
	Hud.reset_phone_state()


func _on_went_outside_find_tricycle () -> void:
	ObjectiveManager.add_objective(scene_objectives[2]["ID"], scene_objectives[2]["text"])
