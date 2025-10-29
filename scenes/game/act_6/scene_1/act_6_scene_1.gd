extends Node

var A_6S_1: Resource
const HOMETOWN = preload("res://scenes/game/act_6/scene_1/hometown.tscn")
const WENDY_HOUSE = preload("res://scenes/game/act_6/scene_1/wendy_house.tscn")
const LARUAN = preload("res://scenes/game/act_6/scene_1/laruan.tscn")
const DARK_FOREST = preload("res://scenes/game/act_6/scene_1/dark_forest.tscn")
const CLIFF = preload("res://scenes/game/act_6/scene_1/cliff.tscn")
const NARRATION_PANEL = preload("res://helpers/narration_panel.tscn")

@onready var locations: Node2D = $locations
var player_wendy: CharacterBody2D
var player_wendy2: CharacterBody2D
var tip_interact: Sprite2D
var tip_interact2: Sprite2D
var current_location: Node
var camera_2d: Camera2D
var wendy_bother: Sprite2D
var gino_shocked: Sprite2D

#NPC
var npc_vanesa: CharacterBody2D
var npc_lola_ising: CharacterBody2D
var npc_aling_theresa: CharacterBody2D
var npc_jonathan: CharacterBody2D
var npc_manong_gino: CharacterBody2D
var npc_manang_matet: CharacterBody2D

#Areas
var house_exit : Area2D
var npc_vanesa_area: Area2D
var npc_lola_ising_area: Area2D
var npc_aling_theresa_area: Area2D
var npc_jonathan_area: Area2D
var npc_manong_gino_area: Area2D
var npc_manang_matet_area: Area2D
var signage1 : Area2D
var signage2 : Area2D


# OBJECTIVES
var scene_objectives = [
	{"ID": 1, "text": "Exit house"},
	{"ID": 2, "text": "Enter town"},
	{"ID": 3, "text": "Find Lola Ising"},
	{"ID": 4, "text": "Talk to neighbors"},
	{"ID": 5, "text": "Go back to Lola ising"},
	{"ID": 6, "text": "Go to laruan"}
]

# triggers
var town_entrance : Area2D
var notice_people : Area2D
var pan_to_lola : Area2D
var contemplate : Area2D
var town_exit : Area2D
var gino_trigger : Area2D
var laruan_exit : Area2D
var dark_forest_exit : Area2D
var danilo_body : Area2D

#Animation
var intro_anim_done : bool = false;

# STATES & FLAGS
var can_use_door := false
var door_interacted := false
var town_entrance_triggered := false
var notice_triggered := false
var pan_triggered := false
var camera_panned_to_lola:= false
var can_talk_to_neighbors: bool = false
var contemplate_triggered := false
var town_exit_triggered := false
var signage1_dialogue_shown := false
var total_neighbors := 5
var lola_final_done := false
var contemplate_enabled := false  
var signage2_dialogue_shown := false

var interacted_lola:= false
var interacted_gino:= false
var interacted_matet:= false
var interacted_vanesa:= false
var interacted_jonathan:= false
var interacted_theresa:= false
var can_interact_lola := false
var can_interact_gino := false
var can_interact_matet := false
var can_interact_vanesa:= false
var can_interact_jonathan := false
var can_interact_theresa := false

var gino_triggered:= false
var current_npc: String

# ===================
# READY
# ===================
func _ready():
	switch_location(NARRATION_PANEL)
	_start_scene()
	_load_dialogue()

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_6/scene_1/a6s1_en.dialogue"
	else:
		path = "res://dialogues/act_6/scene_1/a6s1.dialogue"
	
	A_6S_1 = load(path)
	
# ===================
# START SCENE
# ===================
func _start_scene() -> void:
	await get_tree().process_frame
	var lines = [
		"Danilo was supposed to be home yesterday,",
		"but he didn’t come back. Now Wendy is worried about him.",
		"[shake rate=10 level=15][color=#ff5555] Where are you Danilo? [/color][/shake]"
	]
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_switch_to_wendy_house()
 
func _switch_to_wendy_house() -> void:
	await get_tree().process_frame
	switch_location(WENDY_HOUSE)
	DialogueManager.show_dialogue_balloon(A_6S_1, "start")
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])

func _switch_to_danilo_hometown() -> void:
	await get_tree().process_frame
	switch_location(HOMETOWN)
	_setup_hometown_signage()
	_on_animation_player_animation_finished("intro")

func _switch_to_laruan() -> void:
	await get_tree().process_frame
	switch_location(LARUAN)
	DialogueManager.show_dialogue_balloon(A_6S_1, "wendy_start")
	await DialogueManager.dialogue_ended

func _on_town_exit_entered(body) -> void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	if body == player_wendy:
		ObjectiveManager.complete_objective(5)
		Hud.clear_objectives()
		Hud.hide_objectives()
		_switch_to_laruan()

func _switch_to_dark_forest() -> void:
	await get_tree().process_frame
	switch_location(DARK_FOREST)
	await get_tree().process_frame  # give scene one more frame to initialize
	_setup_darkforest_signage2()
	await get_tree().create_timer(0.1).timeout  # optional fallback
	DialogueManager.show_dialogue_balloon(A_6S_1, "enter_dark_forest")
	await DialogueManager.dialogue_ended

func _on_laruan_exit_entered(body):
	if body.name not in ["player_wendy", "player_wendy2"]:
		return
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_switch_to_dark_forest()

func _switch_to_cliff() -> void:
	await get_tree().process_frame
	switch_location(CLIFF)
	DialogueManager.show_dialogue_balloon(A_6S_1, "cliff_entry")
	DialogueManager.dialogue_ended

func _on_dark_forest_exit_entered(body):
	if body.name not in ["player_wendy", "player_wendy2"]:
		return
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_switch_to_cliff()

func _on_danilo_body_entered(body) -> void:
	if body.name not in ["player_wendy", "player_wendy2"]:
		return
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	DialogueManager.show_dialogue_balloon(A_6S_1, "seen_danilo")
	await DialogueManager.dialogue_ended
	act_6_scene_1_done()

# ===================
# LOCATION HANDLER
# ===================
func switch_location(scene: PackedScene) -> void:
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	current_location = scene.instantiate()
	locations.add_child(current_location)

	player_wendy = current_location.get_node("y-sorted/player_wendy")
	tip_interact = player_wendy.get_node_or_null("tip_interact") if player_wendy else null
	player_wendy2 = current_location.get_node("y-sorted/wendy_and_npcs/player_wendy")
	tip_interact2 = player_wendy2.get_node_or_null("tip_interact") if player_wendy2 else null
	wendy_bother = current_location.get_node("y-sorted/wendy_and_npcs/player_wendy/wendy_bother")
	gino_shocked = current_location.get_node("y-sorted/wendy_and_npcs/npc_gino/gino_shocked")
	
	if not player_wendy2:
		print("⚠️ player_wendy2 not found in:", current_location.name)
	else:
		print("✅ player_wendy2 found in:", current_location.name)
	
	#NPC
	npc_lola_ising = current_location.get_node("y-sorted/npc_lola_ising")
	npc_aling_theresa = current_location.get_node("y-sorted/npc_aling_theresa")
	npc_manang_matet = current_location.get_node("y-sorted/npc_matet")
	npc_manong_gino= current_location.get_node("y-sorted/npc_gino")
	npc_vanesa = current_location.get_node("y-sorted/npc_vanesa")
	npc_jonathan = current_location.get_node("y-sorted/npc_jonathan")
	
	#interactable_area
	npc_lola_ising_area = current_location.get_node("y-sorted/npc_lola_ising/lola_ising")
	npc_aling_theresa_area = current_location.get_node("y-sorted/npc_aling_theresa/aling_theresa")
	npc_manang_matet_area = current_location.get_node("y-sorted/npc_matet/manang_matet")
	npc_manong_gino_area = current_location.get_node("y-sorted/npc_gino/mang_gino")
	npc_vanesa_area = current_location.get_node("y-sorted/npc_vanesa/vanesa")
	npc_jonathan_area = current_location.get_node("y-sorted/npc_jonathan/jonathan")
	
	#trigger
	camera_2d = current_location.get_node_or_null("y-sorted/player_wendy/hometown_Camera2D")
	town_entrance = current_location.get_node_or_null("town_entrance")
	notice_people = current_location.get_node_or_null("notice_people")
	pan_to_lola = current_location.get_node_or_null("pan_to_lola")
	town_exit = current_location.get_node_or_null("town_exit")
	contemplate = current_location.get_node_or_null("contemplate")
	laruan_exit = current_location.get_node_or_null("laruan_exit")
	gino_trigger = current_location.get_node_or_null("gino_trigger")
	dark_forest_exit = current_location.get_node_or_null("dark_forest_exit")
	danilo_body = current_location.get_node_or_null("danilo_body")
	
	if scene == WENDY_HOUSE:
		house_exit = current_location.get_node_or_null("house_exit")
	if house_exit:
		house_exit.body_entered.connect(_on_house_exit_entered)
		house_exit.body_exited.connect(_on_house_exit_exited)
	if town_entrance:
		town_entrance.body_entered.connect(_on_town_entrance_entered)
	if notice_people:
		notice_people.body_entered.connect(_on_notice_people_entered)
	if pan_to_lola:
		pan_to_lola.body_entered.connect(_on_pan_to_lola_entered)
	if npc_lola_ising_area:
		npc_lola_ising_area.body_entered.connect(_on_npc_lola_ising_area_entered)
		npc_lola_ising_area.body_exited.connect(_on_npc_lola_ising_area_exited)	
		if npc_aling_theresa_area:
			npc_aling_theresa_area.body_entered.connect(_on_npc_aling_theresa_area_entered)
			npc_aling_theresa_area.body_exited.connect(_on_npc_aling_theresa_area_exited)
		if npc_manang_matet_area:
			npc_manang_matet_area.body_entered.connect(_on_npc_manang_matet_area_entered)
			npc_manang_matet_area.body_exited.connect(_on_npc_manang_matet_area_exited)
		if npc_manong_gino_area:
			npc_manong_gino_area.body_entered.connect(_on_npc_manong_gino_area_entered)
			npc_manong_gino_area.body_exited.connect(_on_npc_manong_gino_area_exited)
		if npc_vanesa_area:
			npc_vanesa_area.body_entered.connect(_on_npc_vanesa_area_entered)
			npc_vanesa_area.body_exited.connect(_on_npc_vanesa_area_exited)
		if npc_jonathan_area:
			npc_jonathan_area.body_entered.connect(_on_npc_jonathan_area_entered)
			npc_jonathan_area.body_exited.connect(_on_npc_jonathan_area_exited)
	
	if gino_trigger:
		gino_trigger.body_entered.connect(_on_gino_trigger_entered)
	if laruan_exit:
		laruan_exit.body_entered.connect(_on_laruan_exit_entered)
	if dark_forest_exit:
		dark_forest_exit.body_entered.connect(_on_dark_forest_exit_entered)
	if danilo_body:
		danilo_body.body_entered.connect(_on_danilo_body_entered)

# ===================
# AREA HANDLERS
# ===================		
func _on_house_exit_entered(body):
	if body == player_wendy:
		if not door_interacted:
			can_use_door = true
			if tip_interact:
				tip_interact.visible = true

func _on_house_exit_exited(body):
	if body == player_wendy:
		can_use_door = false
		if tip_interact:
			tip_interact.visible = false

func _on_town_entrance_entered(body) -> void:
	if body == player_wendy and not town_entrance_triggered:
		town_entrance_triggered = true
		player_wendy.can_move = false
		DialogueManager.show_dialogue_balloon(A_6S_1, "hometown")
		player_wendy.can_move = true

func _on_notice_people_entered(body) -> void:
	if body != player_wendy or notice_triggered:
		return

	notice_triggered = true
	player_wendy.can_move = false
	await DialogueManager.show_dialogue_balloon(A_6S_1, "notice")
	await DialogueManager.dialogue_ended
	ObjectiveManager.add_objective(scene_objectives[2]["ID"], scene_objectives[2]["text"])
	player_wendy.can_move = true

func _on_pan_to_lola_entered(body: Node) -> void:
	if body != player_wendy:
		return
	if camera_panned_to_lola or pan_triggered:
		return

	player_wendy.animation_locked = true
	player_wendy.can_move = false
	pan_triggered = true
	camera_panned_to_lola = true
	print("Panning camera to Lola...")

	await pan_camera_to_lola()
	DialogueManager.show_dialogue_balloon(A_6S_1, "lola_spotted")

	player_wendy.animation_locked = false
	player_wendy.can_move = true

func _on_npc_lola_ising_area_entered(body):
	if body == player_wendy:
		player_wendy.current_npc = "npc_lola_ising"
		can_interact_lola = true
		if tip_interact:
			tip_interact.visible = true

func _on_npc_lola_ising_area_exited(body):
	if body == player_wendy:
		player_wendy.current_npc = ""
		can_interact_lola = false
		if tip_interact:
			tip_interact.visible = false

func _on_npc_aling_theresa_area_entered(body):
	if body == player_wendy and can_talk_to_neighbors:
		if not interacted_theresa:
			player_wendy.current_npc = "npc_aling_theresa"
			can_interact_theresa = true
			if tip_interact:
				tip_interact.visible = true

func _on_npc_aling_theresa_area_exited(body):
	if body == player_wendy:
		player_wendy.current_npc = ""
		can_interact_theresa = false
		if tip_interact:
			tip_interact.visible = false

func _on_npc_manang_matet_area_entered(body):
	if body == player_wendy and can_talk_to_neighbors:
		if not interacted_matet:
			player_wendy.current_npc = "npc_manang_matet"
			can_interact_matet = true
			if tip_interact:
				tip_interact.visible = true

func _on_npc_manang_matet_area_exited(body):
	if body == player_wendy:
		player_wendy.current_npc = ""
		can_interact_matet = false
		if tip_interact:
			tip_interact.visible = false

func _on_npc_manong_gino_area_entered(body):
	if body == player_wendy and can_talk_to_neighbors:
		if not interacted_gino:
			player_wendy.current_npc = "npc_manong_gino"
			can_interact_gino = true
			if tip_interact:
				tip_interact.visible = true

func _on_npc_manong_gino_area_exited(body):
	if body == player_wendy:
		player_wendy.current_npc = ""
		can_interact_gino = false
		if tip_interact:
			tip_interact.visible = false

func _on_npc_vanesa_area_entered(body):
	if body == player_wendy and can_talk_to_neighbors:
		if not interacted_vanesa:
			player_wendy.current_npc = "npc_vanesa"
			can_interact_vanesa = true
			if tip_interact:
				tip_interact.visible = true

func _on_npc_vanesa_area_exited(body):
	if body == player_wendy:
		player_wendy.current_npc = ""
		can_interact_vanesa = false
		if tip_interact:
			tip_interact.visible = false

func _on_npc_jonathan_area_entered(body):
	if body == player_wendy and can_talk_to_neighbors:
		if not interacted_jonathan:
			player_wendy.current_npc = "npc_jonathan"
			can_interact_jonathan = true
			if tip_interact:
				tip_interact.visible = true

func _on_npc_jonathan_area_exited(body):
	if body == player_wendy:
		player_wendy.current_npc = ""
		can_interact_jonathan = false
		if tip_interact:
			tip_interact.visible = false

func _on_signage1_body_entered(body) -> void:
	if body.name != "player_wendy":
		return
	player_wendy.can_interact = true
	player_wendy.current_npc = "signage1"
	if tip_interact:
		tip_interact.visible = true

func _on_signage1_body_exited(body) -> void:
	if body.name != "player_wendy":
		return
	player_wendy.can_interact = false
	player_wendy.current_npc = ""
	if tip_interact:
		tip_interact.visible = false

func _on_signage2_body_entered(body) -> void:
	if body.name not in ["player_wendy", "player_wendy2"]:
		return
	player_wendy2.can_interact = true
	player_wendy2.current_npc = "signage2"
	if tip_interact2:
		tip_interact2.visible = true

func _on_signage2_body_exited(body) -> void:
	if body.name not in ["player_wendy", "player_wendy2"]:
		return
	player_wendy2.can_interact = false
	player_wendy2.current_npc = ""
	if tip_interact2:
		tip_interact2.visible = false

func _on_contemplate_entered(body) -> void:
	if body == player_wendy and not contemplate_triggered:
		contemplate_triggered = true
		player_wendy.can_move = false
		await DialogueManager.show_dialogue_balloon(A_6S_1, "wendy_contemplate")
		player_wendy.can_move = true

		print("Contemplation done — enabling Lola’s final talk.")
		can_interact_lola = true

func _on_gino_trigger_entered(body) -> void:
	if body != player_wendy2 or gino_triggered:
		return

	gino_triggered = true
	player_wendy2.can_move = false
	wendy_bother.visible = true
	gino_shocked.visible = true
	await DialogueManager.show_dialogue_balloon(A_6S_1, "mang_gino_Cliff_hint")
	await DialogueManager.dialogue_ended
	player_wendy2.can_move = true
	wendy_bother.visible = false
	gino_shocked.visible = false

# ===================
# INPUT HANDLER
# ===================
func _process(_delta):
	# Door interaction
	if can_use_door and not door_interacted and Input.is_action_just_pressed("interact"):
		_door_interacted()
	
	if can_interact_lola and Input.is_action_just_pressed("interact"):
		_lola_ising_interacted()
	
	# Neighbor interactions (only after Lola)
	if can_talk_to_neighbors:
		if can_interact_jonathan and not interacted_jonathan and Input.is_action_just_pressed("interact"):
			_jonathan_interacted()

		if can_interact_vanesa and not interacted_vanesa and Input.is_action_just_pressed("interact"):
			_vanesa_interacted()

		if can_interact_matet and not interacted_matet and Input.is_action_just_pressed("interact"):
			_manang_matet_interacted()

		if can_interact_gino and not interacted_gino and Input.is_action_just_pressed("interact"):
			_manong_gino_interacted()

		if can_interact_theresa and not interacted_theresa and Input.is_action_just_pressed("interact"):
			_aling_theresa_interacted()

	# Signage interactions
	if Input.is_action_just_pressed("interact"):
		# Signage1 - Neighborhood / Wendy House
		if player_wendy and player_wendy.can_interact and player_wendy.current_npc == "signage1":
			if not Hud.popup_showing:
				player_wendy.last_direction = Vector2.UP
				Hud.add_popup_image("res://assets/HUD/signage_laruan.png")
				Hud._toggle_popup()
				player_wendy.force_cannot_move = true

				if not signage1_dialogue_shown:
					signage1_dialogue_shown = true
					await get_tree().create_timer(0.5).timeout
					DialogueManager.show_dialogue_balloon(A_6S_1, "signage1")
			else:
				Hud._toggle_popup()
				player_wendy.force_cannot_move = false

		# Signage2 - Dark Forest / Laruan
		if player_wendy2 and player_wendy2.can_interact and player_wendy2.current_npc == "signage2":
			if not Hud.popup_showing:
				player_wendy2.last_direction = Vector2.UP
				Hud.add_popup_image("res://assets/HUD/signage_darkforest.png")
				Hud._toggle_popup()
				player_wendy2.force_cannot_move = true

				if not signage2_dialogue_shown:
					signage2_dialogue_shown = true
					await get_tree().create_timer(0.5).timeout
					DialogueManager.show_dialogue_balloon(A_6S_1, "signage_darkforest")
			else:
				Hud._toggle_popup()
				player_wendy2.force_cannot_move = false


# ===================
# INTERACTIONS
# ===================
func _door_interacted():
	door_interacted = true
	can_use_door = false

	# Choose whichever player exists
	var active_player = player_wendy if player_wendy else player_wendy2
	var active_tip = tip_interact if tip_interact else tip_interact2

	# Safely hide tip
	if active_tip:
		active_tip.visible = false

	# Optional safety: prevent both players from moving during transition
	if active_player:
		active_player.force_cannot_move = true

	TransitionFade.transition()
	await SignalBus.on_transition_finished

	# Mark objective and handle HUD safely
	if ObjectiveManager:
		ObjectiveManager.complete_objective(0)
	if Hud:
		Hud.hide_objectives()
		Hud.clear_objectives()

	# Scene switch (assuming this is only for Wendy)
	_switch_to_danilo_hometown()


func _lola_ising_interacted():
	if tip_interact:
		tip_interact.visible = false

	var neighbor_obj = ObjectiveManager.objectives.get(scene_objectives[3]["ID"])
	
	var current_npc = player_wendy.current_npc
	if current_npc == "npc_lola_ising":
		npc_face_player(npc_lola_ising, player_wendy.global_position)
		
	# --- [3RD / FINAL TALK] ---
	# Happens only after Wendy contemplates
	if contemplate_triggered and not lola_final_done: 
		lola_final_done = true
		can_interact_lola = false
		print("Playing Lola FINAL dialogue (after contemplate).")
		player_wendy.set_physics_process(false)
		await DialogueManager.show_dialogue_balloon(A_6S_1, "lola_final")
		player_wendy.set_physics_process(true)
		ObjectiveManager.complete_objective(scene_objectives[4]["ID"])
		ObjectiveManager.add_objective(scene_objectives[5]["ID"], scene_objectives[5]["text"])
		
		# Enable town exit after final talk
		if town_exit and not town_exit.is_connected("body_entered", Callable(self, "_on_town_exit_entered")):
			town_exit.body_entered.connect(_on_town_exit_entered)
			print("Town Exit is now active!")
		return

	# --- [1ST TALK] ---
	# Starts the neighbor quest
	if not interacted_lola:
		print("First time talking to Lola — starting neighbor quest.")
		interacted_lola = true
		can_interact_lola = true  # allow future talks
		ObjectiveManager.complete_objective(scene_objectives[2]["ID"])
		await DialogueManager.show_dialogue_balloon(A_6S_1, "talk_to_lola_ising")
		await DialogueManager.dialogue_ended
		ObjectiveManager.add_progress_objective(
			scene_objectives[3]["ID"],
			scene_objectives[3]["text"],
			total_neighbors
		)

		can_talk_to_neighbors = true
		return

	if neighbor_obj and neighbor_obj["current"] < neighbor_obj["goal"]:
		print("Lola reminds Wendy to finish talking to neighbors.")
		player_wendy.set_physics_process(false)
		await DialogueManager.show_dialogue_balloon(A_6S_1, "lola_here")
		player_wendy.set_physics_process(true)
		return

func _jonathan_interacted():
	var current_npc = player_wendy.current_npc
	if current_npc == "npc_jonathan":
		npc_face_player(npc_jonathan, player_wendy.global_position)
	
	if not can_talk_to_neighbors:
		return
	interacted_jonathan = true
	can_interact_jonathan = false
	if tip_interact:
		tip_interact.visible = false
	DialogueManager.show_dialogue_balloon(A_6S_1, "talk_to_jonathan")
	_add_neighbor_progress()
	_check_all_neighbors_talked()

func _manang_matet_interacted():
	var current_npc = player_wendy.current_npc
	if current_npc == "npc_manang_matet":
		npc_face_player(npc_manang_matet, player_wendy.global_position)
	
	if not can_talk_to_neighbors:
		return
	interacted_matet = true
	can_interact_matet = false
	if tip_interact:
		tip_interact.visible = false
	DialogueManager.show_dialogue_balloon(A_6S_1, "talk_to_manang_matet")
	_add_neighbor_progress()
	_check_all_neighbors_talked()

func _manong_gino_interacted():
	var current_npc = player_wendy.current_npc
	if current_npc == "npc_manong_gino":
		npc_face_player(npc_manong_gino, player_wendy.global_position)
	
	if not can_talk_to_neighbors:
		return
	interacted_gino = true
	can_interact_gino = false
	if tip_interact:
		tip_interact.visible = false
	DialogueManager.show_dialogue_balloon(A_6S_1, "talk_to_mang_gino")
	_add_neighbor_progress()
	_check_all_neighbors_talked()

func _aling_theresa_interacted():
	var current_npc = player_wendy.current_npc
	if current_npc == "npc_aling_theresa":
		npc_face_player(npc_aling_theresa, player_wendy.global_position)
		
	if not can_talk_to_neighbors:
		return
	interacted_theresa = true
	can_interact_theresa = false
	if tip_interact:
		tip_interact.visible = false
	DialogueManager.show_dialogue_balloon(A_6S_1, "talk_to_aling_theresa")
	_add_neighbor_progress()
	_check_all_neighbors_talked()

func _vanesa_interacted():
	var current_npc = player_wendy.current_npc
	if current_npc == "npc_vanesa":
		npc_face_player(npc_vanesa, player_wendy.global_position)
		
	if not can_talk_to_neighbors:
		return
	interacted_vanesa = true
	can_interact_vanesa = false
	if tip_interact:
		tip_interact.visible = false
	DialogueManager.show_dialogue_balloon(A_6S_1, "talk_to_vanesa")
	_add_neighbor_progress()
	_check_all_neighbors_talked()

# ===================
# ANIMATION
# ===================
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	player_wendy.force_cannot_move = false;
	intro_anim_done  = true;
	ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"])

func pan_camera_to_lola() -> void:
	player_wendy.animation_locked = true
	player_wendy.can_move = false

	var camera_parent = camera_2d.get_parent()
	var camera_global_pos = camera_2d.global_position
	camera_2d.get_parent().remove_child(camera_2d)
	add_child(camera_2d)
	camera_2d.global_position = camera_global_pos

	var start_position = player_wendy.global_position
	var lola_position = npc_lola_ising.global_position
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(camera_2d, "global_position", lola_position, 1.0)
	tween.tween_callback(func(): print("Camera reached lola"))
	tween.tween_interval(1.0)
	tween.tween_property(camera_2d, "global_position", start_position, 1.0)
	tween.tween_callback(func(): print("Camera back to player"))

	await tween.finished

	remove_child(camera_2d)
	camera_parent.add_child(camera_2d)
	camera_2d.position = Vector2.ZERO 

	camera_panned_to_lola = false
	print("Camera pan sequence complete")
	player_wendy.animation_locked = false
	player_wendy.can_move = true

# ===================
# HELPERS
# ===================
func _add_neighbor_progress():
	ObjectiveManager.update_progress(scene_objectives[3]["ID"], 1)
	var neighbor_obj = ObjectiveManager.objectives.get(scene_objectives[3]["ID"])
	print("Neighbor progress:", neighbor_obj)  # debug
	if neighbor_obj and neighbor_obj["current"] >= neighbor_obj["goal"] and not contemplate_triggered:
		print("All 5 neighbors talked to — enabling Contemplate area.")
		ObjectiveManager.add_objective(scene_objectives[4]["ID"], scene_objectives[4]["text"])
		if contemplate and not contemplate.is_connected("body_entered", Callable(self, "_on_contemplate_entered")):
			contemplate.body_entered.connect(_on_contemplate_entered, CONNECT_DEFERRED)

func _check_all_neighbors_talked():
	# Check if all neighbors have been interacted with
	if interacted_gino and interacted_matet and interacted_vanesa and interacted_jonathan and interacted_theresa:
		if not contemplate_enabled:
			print("✅ All neighbors talked to — enabling Contemplate manually.")
			_enable_contemplate()

func _enable_contemplate():
	if contemplate_enabled:
		return
	contemplate_enabled = true

	if contemplate and not contemplate.is_connected("body_entered", Callable(self, "_on_contemplate_entered")):
		contemplate.body_entered.connect(_on_contemplate_entered, CONNECT_DEFERRED)
		print("Contemplate area connected!")

	ObjectiveManager.add_objective(scene_objectives[4]["ID"], scene_objectives[4]["text"])

func _setup_hometown_signage():
	signage1 = current_location.get_node_or_null("signage1")

	if signage1:
		signage1.body_entered.connect(_on_signage1_body_entered)
		signage1.body_exited.connect(_on_signage1_body_exited)
		print("Signage connected in Hometown")

func _setup_darkforest_signage2():
	signage2 = current_location.get_node_or_null("signage2")
	if signage2:
		signage2.body_entered.connect(_on_signage2_body_entered)
		signage2.body_exited.connect(_on_signage2_body_exited)
		print("Signage2 connected in Dark Forest")
	else:
		print("⚠️ signage2 node not found in this scene")


func npc_face_player(npc: CharacterBody2D, player_position: Vector2) -> void:
	var direction_to_player = player_position - npc.global_position
	
	# Use the axis with the larger absolute difference
	if abs(direction_to_player.x) > abs(direction_to_player.y):
		npc.direction = Vector2.RIGHT if direction_to_player.x > 0 else Vector2.LEFT
	
	await get_tree().process_frame
	npc.direction = Vector2.ZERO

func set_wendy_idle_up() -> void:
	if not current_location:
		print("⚠️ No current_location found.")
		return

	var player_node = current_location.get_node_or_null("y-sorted/player_wendy")
	if not player_node:
		print("❌ player_wendy not found in", current_location.name)
		return

	var animated_wendy = player_node.get_node_or_null("AnimatedSprite2D")
	if animated_wendy:
		print("✅ Wendy idle_up found and playing animation.")
		animated_wendy.play("idle_up")
	else:
		print("❌ AnimatedSprite2D not found inside player_wendy")

# ===================
# COMPLETE SCENE
# ===================
func act_6_scene_1_done() -> void:
	SaveManager.game_save.current_act = "act_6"
	SaveManager.game_save.current_scene = "scene_1"
	SaveManager.save_game()
	print("ACT 6 SCENE 1 DONE")
	SignalBus.act_num_scene_num_done.emit(
		"act_6", 
		"scene_1", 
        "res://scenes/game/act_6/scene_2.tscn"
	)
