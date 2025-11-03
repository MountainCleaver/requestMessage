extends Node2D

# === PRELOADS ===
var A_2S_3: Resource

@onready var bus_trigger: Area2D = $"bus_terminal/bus_trigger"
@onready var phone_trigger: Area2D = $"bus_terminal/phone_trigger"
@onready var player_danilo: CharacterBody2D = $"bus_terminal/y-sorted2/player_danilo"
@onready var entrance: Area2D = $bus_terminal/entrance
@onready var npc_area: Area2D = $"bus_terminal/y-sorted2/npcs_collidable/StaticBody2D/npc"
@onready var bus: AnimatedSprite2D = $"bus_terminal/y-sorted2/StaticBody2D/bus"
@onready var bus_interact: Area2D = $"bus_terminal/y-sorted2/StaticBody2D/bus/bus_interact"
@onready var jeep: AnimatedSprite2D = $"bus_terminal/y-sorted2/jeep"
@onready var camera_2d: Camera2D = $"bus_terminal/y-sorted2/player_danilo/Camera2D"

@onready var car_noise: AudioStreamPlayer = $SFX_CAR
@onready var sfx_notif: AudioStreamPlayer = $SFX_NOTIF

@onready var bus_areas = {
	"montelargo": $bus_areas/montelargo,
	"santa_claridad": $bus_areas/santa_claridad,
	"san_martino": $bus_areas/san_martino,
	"granada_del_sur": $bus_areas/granada_del_sur,
	"balete_viejo": $bus_areas/balete_viejo,
	"nueva_esperanza": $bus_areas/nueva_esperanza
}

var looked_bus = { 
	"montelargo": false, 
	"santa_claridad": false, 
	"san_martino": false, 
	"granada_del_sur": false, 
	"balete_viejo": false, 
	"nueva_esperanza": false 
}
	
var bus_dialogues = { 
	"montelargo": "Bus_1", 
	"nueva_esperanza": "Bus_2", 
	"san_martino": "Bus_3", 
	"santa_claridad": "Bus_4", 
	"balete_viejo": "Bus_5", 
	"granada_del_sur": "Bus_6" 
}

var bus_hud_images = {
	"montelargo": "res://assets/HUD/signage_bus_terminal_montelargo.png",
	"nueva_esperanza": "res://assets/HUD/signage_bus_terminal_nuevaEsperanza.png",
	"san_martino": "res://assets/HUD/signage_bus_terminal_sanmartino.png",
	"santa_claridad": "res://assets/HUD/signage_bus_terminal_santaClaridad.png",
	"balete_viejo": "res://assets/HUD/signage_bus_terminal_baleteviejo.png",
	"granada_del_sur": "res://assets/HUD/signage_bus_terminal_granadadelsur.png"
}

var dialogue_to_bus = { 
	"bus_1": "montelargo", 
	"bus_2": "nueva_esperanza", 
	"bus_3": "san_martino", 
	"bus_4": "santa_claridad", 
	"bus_5": "balete_viejo", 
	"bus_6": "granada_del_sur" 
}

var intro_anim_done : bool = false;
var npc_talked: bool = false 
var santa_claridad_found := false
var camera_panned_to_bus: bool = false
var unknown_sender_opened: bool = false

# Phone local flags
var phone_showing: bool = false
var lock_screen_active: bool = false
var phone_main_active: bool = false
var chat_open: bool = false

func _ready() -> void:
	_game_state_flow()
	_load_dialogue()
	car_noise.play()
	player_danilo.force_cannot_move = true;
	entrance.body_entered.connect(_on_entrance_body_entered)
	setup_bus_connections()
	npc_area.body_entered.connect(func(body): _on_npc_body_entered(body, "ticket_npc"))
	npc_area.body_exited.connect(func(body): _on_npc_body_exited(body, "ticket_npc"))
	bus.visible = false
	
	# PHONE STARTS HIDDEN AND INACTIVE
	phone_trigger.visible = false
	phone_trigger.monitoring = false
	phone_trigger.set_deferred("monitorable", false)
	phone_trigger.body_entered.connect(_on_phone_trigger_body_entered)
	
	bus_interact.body_entered.connect(func(body): _on_bus_interact_body_entered(body, "bus_interact"))
	bus_interact.body_exited.connect(func(body): _on_bus_interact_body_exited(body, "bus_interact"))
	bus_interact.monitoring = false
	bus_interact.set_deferred("monitorable", false)

func _game_state_flow() -> void:
	FlashlightManager.set_current_scene("act_2", "scene_3")
	FlashlightManager.disable_flashlights()
	# PUT THIS AT THE BEGINNING OF FUNC _READY
	GameState.load_game()
	GameState.current_act = "act_2"
	GameState.current_scene = "scene_3"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_2/scene_3/a2s3_en.dialogue"
	else:
		path = "res://dialogues/act_2/scene_3/a2s3.dialogue"
	
	A_2S_3 = load(path)
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	player_danilo.force_cannot_move = false;
	intro_anim_done  = true;
	Hud.show_objectives();
	ObjectiveManager.add_objective(1, "Enter bus terminal.")
	car_noise.stop()

func _on_entrance_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	DialogueManager.show_dialogue_balloon(A_2S_3, "start")
	await get_tree().process_frame
	ObjectiveManager.complete_objective(1)
	ObjectiveManager.add_objective(2, "Find bus to Santa Claridad.")
	entrance.body_entered.disconnect(_on_entrance_body_entered)
	bus_trigger.monitoring = false
	bus_trigger.set_deferred("monitorable", false)
	

func _input(event: InputEvent) -> void:
	if not (event.is_action_pressed("interact") and player_danilo.can_interact):
		return

	var target = player_danilo.current_npc

	# === 1️⃣ BUS INTERACTION ===
	if target in bus_dialogues:
		if not target or looked_bus.get(target, false):
			return

		player_danilo.force_cannot_move = true
		Hud.add_popup_image(bus_hud_images[target])
		Hud._toggle_popup()
		print("Interacted with ", target, " bus")
		await wait_for_hud_closed()

		DialogueManager.show_dialogue_balloon(A_2S_3, bus_dialogues[target])
		set_bus_used(target)

		if target == "santa_claridad":
			santa_claridad_found = true
			for key in bus_areas.keys():
				if bus_areas[key]:
					bus_areas[key].monitoring = false
					bus_areas[key].set_deferred("monitorable", false)
			print("All bus interactions disabled after Santa Claridad.")

		player_danilo.force_cannot_move = false
		player_danilo.can_move = true
		player_danilo.animation_locked = false
		player_danilo.is_running = false

	# === 2️⃣ NPC INTERACTION ===
	elif target == "ticket_npc":
		if looked_bus["santa_claridad"] == false:
			DialogueManager.show_dialogue_balloon(A_2S_3, "Npc")
			return

		if npc_talked:
			player_danilo.can_interact = false
			return

		print("Interacting with NPC")
		player_danilo.force_cannot_move = true
		DialogueManager.show_dialogue_balloon(A_2S_3, "Buy_ticket")
		npc_talked = true
		enable_bus_trigger()
		enable_phone_trigger()
		player_danilo.force_cannot_move = false
		player_danilo.can_interact = false

	# === 3️⃣ END SCENE (bus_interact) ===
	elif target == "bus_interact":
		print("ACT 2 SCENE 3 DONE")
		player_danilo.force_cannot_move = true
		player_danilo.can_move = false
		player_danilo.can_interact = false

		SaveManager.game_save.current_act = "act_2"
		SaveManager.game_save.current_scene = "scene_3"
		
		SaveManager.save_game()
		GameState.save_game()
		
		SignalBus.act_num_scene_num_done.emit(
			"act_2",
			"scene_3",
			"res://scenes/game/act_2/scene_4/act_2_scene_4.tscn"
		)

		ObjectiveManager.complete_objective(4)
		await get_tree().process_frame
		Hud.hide_objectives()
		Hud.clear_objectives()

	else:
		# No valid interaction target
		return 
	

func setup_bus_connections() -> void:
	for bus_name in bus_areas.keys():
		var area = bus_areas[bus_name]
		area.body_entered.connect(func(body: Node2D): bus_entered(body, bus_name))
		area.body_exited.connect(func(body: Node2D): bus_exited(body, bus_name))

func bus_entered(body: Node2D, bus_name: String) -> void:
	if body.name != "player_danilo":
		return
	
	if not looked_bus[bus_name]:
		SignalBus.in_npc.emit(bus_name)
		print("in " + bus_name)
		player_danilo.can_interact = true

func bus_exited(body: Node2D, bus_name: String) -> void:
	if body.name != "player_danilo":
		return
	SignalBus.out_npc.emit(bus_name)

func set_bus_used(bus_name: String) -> void:
	looked_bus[bus_name] = true
	print(bus_name + " is now used and can't be interacted with again")

func wait_for_hud_closed() -> void:
	while Hud.popup_showing:
		await get_tree().process_frame

func _on_npc_body_entered(body: Node2D, npc: String) -> void:
	if body.name != "player_danilo":
		return
	SignalBus.in_npc.emit(npc)

func _on_npc_body_exited(body: Node2D, npc: String) -> void:
	if body.name != "player_danilo":
		return
	SignalBus.out_npc.emit(npc)

func _on_bus_trigger_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo" and not camera_panned_to_bus:
		bus.visible = true
		print("play camera")
		camera_panned_to_bus = true
		await pan_camera_to_bus()

func pan_camera_to_bus() -> void:
	player_danilo.animation_locked = true
	player_danilo.can_move = false

	var camera_parent = camera_2d.get_parent()
	var camera_global_pos = camera_2d.global_position
	camera_2d.get_parent().remove_child(camera_2d)
	add_child(camera_2d)
	camera_2d.global_position = camera_global_pos

	var start_position = player_danilo.global_position
	var bus_position = bus.global_position
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(camera_2d, "global_position", bus_position, 1.0)
	tween.tween_callback(func(): print("Camera reached Bus"))
	tween.tween_interval(1.0)
	tween.tween_property(camera_2d, "global_position", start_position, 1.0)
	tween.tween_callback(func(): print("Camera back to player"))

	await tween.finished

	remove_child(camera_2d)
	camera_parent.add_child(camera_2d)
	camera_2d.position = Vector2.ZERO 

	camera_panned_to_bus = false
	print("Camera pan sequence complete")
	player_danilo.animation_locked = false
	player_danilo.can_move = true
	bus_trigger.monitoring = false

func enable_bus_trigger():
	bus_trigger.monitoring = true
	bus_trigger.set_deferred("monitorable", true)
	print("Bus trigger activated — player can now board the bus.")

# Magvibrate yung phone then labas yung hud ng phone then chat ni unknown sender
func _on_phone_trigger_body_entered(body: Node2D) -> void:
	sfx_notif.play()
	if body.name != "player_danilo":
		return

	SignalBus.unknown_sender_unlocked = true
	phone_showing = false
	lock_screen_active = false
	phone_main_active = false
	chat_open = false

	if not unknown_sender_opened:
		Hud.show_phone_with_unknown_sender()
		await get_tree().create_timer(1).timeout
		player_danilo.force_cannot_move = true
		_on_chat_opened("unknown_sender")

	phone_trigger.monitoring = false
	phone_trigger.visible = false

	player_danilo.force_cannot_move = false
	player_danilo.can_move = true
	player_danilo.can_interact = true
	enable_bus_interact()
	
func _on_chat_opened(chat_name: String) -> void:
	if chat_name == "unknown_sender" and not unknown_sender_opened:
		unknown_sender_opened = true
		# KAPAG PINAKITA WENDY CHAT MAGCHECHECK NA RIN OBJECTIVE NA NAOPEN NA
		DialogueManager.show_dialogue_balloon(A_2S_3, "unknown_message")
		await get_tree().create_timer(1).timeout
		
func enable_phone_trigger():
	phone_trigger.visible = true
	phone_trigger.monitoring = true
	phone_trigger.set_deferred("monitorable", true)
	print("See phone.")

func _on_bus_interact_body_entered(body: Node2D, bus_interact: String) -> void:
	if body.name != "player_danilo":
		return
	SignalBus.in_npc.emit(bus_interact)

func _on_bus_interact_body_exited(body: Node2D, bus_interact: String) -> void:
	if body.name != "player_danilo":
		return
	SignalBus.out_npc.emit(bus_interact)
	
func enable_bus_interact() -> void:
	bus_interact.monitoring = true
	bus_interact.set_deferred("monitorable", true)
	print("Bus interact is now active — player can board the bus.")
