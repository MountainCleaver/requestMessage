extends Node2D

# === PRELOADS ===
const A_4S_2 = preload("res://dialogues/act_4/a4s2.dialogue")
const SMALLHUT = preload("res://scenes/game/act_4/scene_2/small_hut.tscn")

@onready var player_danilo: CharacterBody2D = $"y-sorted/player_danilo"
@onready var grave_entry: Area2D = $"Interactable/grave_entry"
@onready var house_enter: Area2D = $"Interactable/house_enter"
@onready var phone_trigger: Area2D = $"Interactable/phone_trigger"
@onready var tip: Sprite2D = $"y-sorted/player_danilo/tip_interact"
@onready var animated_sprite_2d: AnimatedSprite2D = player_danilo.get_node("AnimatedSprite2D")

var dialogue_shown: bool = false
var house_interacted: bool = false
var unknown_sender_opened: bool = false
var phone_showing: bool = false
var lock_screen_active: bool = false
var phone_main_active: bool = false
var chat_open: bool = false

@onready var dirt_sprites= {
	"dirt_1": DIRT1.get_node("Sprite2D"),
	"dirt_2": DIRT1.get_node("Sprite2D"),
	"dirt_3": player_danilo.get_node("AnimatedSprite2D"),
	"dirt_4": player_danilo.get_node("AnimatedSprite2D"),
	"dirt_5": player_danilo.get_node("AnimatedSprite2D"),
	"dirt_6": $"y-sorted/DIRT1/dirt_6",
	"dirt_7": $"y-sorted/DIRT1/dirt_7",
	"dirt_8": $"y-sorted/DIRT1/dirt_8"
}

@onready var dirt_areas = {
	"dirt_1": $Interactable/dirt_areas/d1,
	"dirt_2": $Interactable/dirt_areas/d2,
	"dirt_3": $Interactable/dirt_areas/d3,
	"dirt_4": $Interactable/dirt_areas/d4,
	"dirt_5": $Interactable/dirt_areas/d5,
	"dirt_6": $Interactable/dirt_areas/d6,
	"dirt_7": $Interactable/dirt_areas/d7,
	"dirt_8": $Interactable/dirt_areas/d8
}

var dirt_dug = { 
	"dirt_1": false, 
	"dirt_2": false, 
	"dirt_3": false, 
	"dirt_4": false, 
	"dirt_5": false, 
	"dirt_6": false,
	"dirt_7": false, 
	"dirt_8": false
}

var dirt_dialogues = { 
	"dirt_1": "dirt_1", 
	"dirt_2": "dirt_2", 
	"dirt_3": "dirt_3", 
	"dirt_4": "dirt_4", 
	"dirt_5": "dirt_5", 
	"dirt_6": "dirt_6", 
	"dirt_7": "dirt_7", 
	"dirt_8": "dirt_8"
}

var dialogues_to_dirt = { 
	"dirt_1": "dirt_1", 
	"dirt_2": "dirt_2", 
	"dirt_3": "dirt_3", 
	"dirt_4": "dirt_4", 
	"dirt_5": "dirt_5", 
	"dirt_6": "dirt_6", 
	"dirt_7": "dirt_7", 
	"dirt_8": "dirt_8"
}

func _ready():
	tip.visible = false
	house_enter.body_entered.connect(_on_house_enter_body_entered)
	
	phone_trigger.visible = false
	phone_trigger.monitoring = false
	phone_trigger.set_deferred("monitorable", false)
	phone_trigger.body_entered.connect(_on_phone_trigger_body_entered)
	

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
		
	if player_danilo.can_interact and player_danilo.current_npc == "signage":
		player_danilo.last_direction = Vector2.UP
		Hud.add_popup_image("res://assets/HUD/signage_darkforest.png")
		Hud._toggle_popup()
		player_danilo.force_cannot_move = Hud.popup_showing
		print("Signage interacted — HUD shown")

		if not dialogue_shown:
			dialogue_shown = true
			await get_tree().create_timer(0.5).timeout 
			DialogueManager.show_dialogue_balloon(A_4S_2, "grave_entry")
	
	elif player_danilo.can_interact and player_danilo.current_npc == "house_enter":
		player_danilo.last_direction = Vector2.UP
		DialogueManager.show_dialogue_balloon(A_4S_2, "smallhut_lock")
		enable_phone_trigger()
		tip.visible = false
		setup_dirt_connections()
		house_interacted = true
		
	# === DIRT INTERACTION HANDLING ===
	for dirt_name in dirt_areas.keys():
		if player_danilo.can_interact and player_danilo.current_npc == dirt_name and not dirt_dug[dirt_name]:
			await dig_anim()
			
			# Update dirt sprite region after digging
			if dirt_sprites.has(dirt_name):
				var sprite = dirt_sprites[dirt_name]
				sprite.region_enabled = true
				sprite.region_rect = Rect2(46.546, -0.515, 29.152, 33.414)
			
			# Mark as used
			set_dirt_used(dirt_name)
			
			# Check if it's dirt_7 (the special one)
			if dirt_name == "dirt_7":
				print("Special dirt found! Unlocking house and transitioning...")
				DialogueManager.show_dialogue_balloon(A_4S_2, "dirt_7")
				
				# Re-enable house_enter interaction
				house_enter.set_deferred("monitoring", true)
				house_enter.set_deferred("monitorable", true)
				player_danilo.current_npc = "house_enter"
				player_danilo.can_interact = true
				
				await get_tree().create_timer(2.0).timeout
				_transition_to_smallhut()
			else:
				# Normal dirt dialogue
				DialogueManager.show_dialogue_balloon(A_4S_2, dirt_dialogues[dirt_name])
			
			break  # stop loop once one dirt is interacted
	
func _on_grave_entry_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	DialogueManager.show_dialogue_balloon(A_4S_2, "grave_entry")
	await get_tree().process_frame
	grave_entry.body_entered.disconnect(_on_grave_entry_body_entered)

func _on_house_enter_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	if house_interacted:
		tip.visible = false
		player_danilo.can_interact = false
	else:
		player_danilo.current_npc = "house_enter"
		player_danilo.can_interact = true
		tip.visible = true


func _on_phone_trigger_body_entered(body: Node2D) -> void:
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
		player_danilo.can_move = true
		
	phone_trigger.monitoring = false
	phone_trigger.visible = false

	player_danilo.force_cannot_move = false
	player_danilo.can_move = true
	player_danilo.can_interact = true

func enable_phone_trigger():
	phone_trigger.visible = true
	phone_trigger.monitoring = true
	phone_trigger.set_deferred("monitorable", true)
	print("See phone.")

func _on_chat_opened(chat_name: String) -> void:
	if chat_name == "unknown_sender" and not unknown_sender_opened:
		unknown_sender_opened = true
		DialogueManager.show_dialogue_balloon(A_4S_2, "unknown_sender_clue")
		await get_tree().create_timer(1).timeout
		await get_tree().process_frame

func dig_anim() -> void:
	player_danilo.animation_locked = true
	player_danilo.can_move = false

	var dir = player_danilo.last_direction

	if dir == Vector2.DOWN:
		animated_sprite_2d.play("digging_down")
	elif dir == Vector2.UP:
		animated_sprite_2d.play("digging_up")
	elif dir == Vector2.LEFT:
		animated_sprite_2d.play("digging_left")
	elif dir == Vector2.RIGHT:
		animated_sprite_2d.play("digging_right")
	else:
		animated_sprite_2d.play("digging_down")

	await animated_sprite_2d.animation_finished

	player_danilo.animation_locked = false
	player_danilo.can_move = true

func setup_dirt_connections() -> void:
	for dirt_name in dirt_areas.keys():
		var area = dirt_areas[dirt_name]
		area.body_entered.connect(func(body: Node2D): dirt_entered(body, dirt_name))
		area.body_exited.connect(func(body: Node2D): dirt_exited(body, dirt_name))

func dirt_entered(body: Node2D, dirt_name: String) -> void:
	if body.name != "player_danilo":
		return
	
	# Only allow if not already dug
	if not dirt_dug[dirt_name]:
		player_danilo.current_npc = dirt_name
		player_danilo.can_interact = true
		tip.visible = true
		print("Player entered " + dirt_name + " — tip shown")
	else:
		# If already dug, disable interaction
		player_danilo.can_interact = false
		tip.visible = false
		print(dirt_name + " already used — interaction disabled")

func dirt_exited(body: Node2D, dirt_name: String) -> void:
	if body.name != "player_danilo":
		return
	
	# Hide tip when leaving
	if not dirt_dug[dirt_name]:
		tip.visible = false
		print("Player exited " + dirt_name + " — tip hidden")
	
	# Reset interaction state
	if player_danilo.current_npc == dirt_name:
		player_danilo.current_npc = ""
		player_danilo.can_interact = false

func set_dirt_used(dirt_name: String) -> void:
	dirt_dug[dirt_name] = true
	print(dirt_name + " is now used and can't be interacted with again")

func _transition_to_smallhut() -> void:
	TransitionFade.transition();
	player_danilo.can_move = false
	await get_tree().create_timer(3,0).timeout 
	get_tree().change_scene_to_packed(SMALLHUT)
