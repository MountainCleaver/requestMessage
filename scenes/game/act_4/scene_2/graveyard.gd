extends Node2D

signal key_found
signal hut_entered
signal grave_exit_triggered

# === PRELOADS ===
const A_4S_2 = preload("res://dialogues/act_4/a4s2.dialogue")

# === NODES ===
@onready var player_danilo: CharacterBody2D = $"y-sorted/player_danilo"
@onready var grave_entry: Area2D = $"Interactable/grave_entry"
@onready var house_enter: Area2D = $"Interactable/house_enter"
@onready var grave_exit: Area2D = $"Interactable/grave_exit"
@onready var phone_trigger: Area2D = $"Interactable/phone_trigger"
@onready var tip: Sprite2D = $"y-sorted/player_danilo/tip_interact"
@onready var animated_sprite_2d: AnimatedSprite2D = player_danilo.get_node("AnimatedSprite2D")
@onready var key: Sprite2D = $"KEY/key"
@onready var mark: Sprite2D = $"y-sorted/player_danilo/question"
@onready var key_area: Area2D = $"Interactable/Key"
@onready var house_exit: Marker2D = $House_exit

# === DIRT REFERENCES ===
@onready var dirt_sprites = {
	"dirt_1": $"y-sorted/DIRT1/dirt_1",
	"dirt_2": $"y-sorted/DIRT2/dirt_2",
	"dirt_3": $"y-sorted/DIRT3/dirt_3",
	"dirt_4": $"y-sorted/DIRT4/dirt_4",
	"dirt_5": $"y-sorted/DIRT5/dirt_5",
	"dirt_6": $"y-sorted/DIRT6/dirt_6",
	"dirt_7": $"y-sorted/DIRT7/dirt_7",
	"dirt_8": $"y-sorted/DIRT8/dirt_8"
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
	"dirt_1": false, "dirt_2": false, "dirt_3": false, "dirt_4": false,
	"dirt_5": false, "dirt_6": false, "dirt_7": false, "dirt_8": false
}

var dirt_dialogues = {
	"dirt_1": "dirt_1", "dirt_2": "dirt_2", "dirt_3": "dirt_3", "dirt_4": "dirt_4",
	"dirt_5": "dirt_5", "dirt_6": "dirt_6", "dirt_7": "dirt_7", "dirt_8": "dirt_8"
}

# === VARIABLES ===
var house_interacted := false
var unknown_sender_opened := false
var phone_showing := false
var dirt_connections_done := false
var dirt_unlocked := false
var key_collected := false
var key_available := false
var grave_entry_triggered := false
var from_hut: bool = false
var hut_already_entered: bool = false

# === READY ===
func _ready():
	tip.visible = false
	mark.visible = false
	setup_dirt_connections()
	disable_all_dirts()

	# Connect interactions
	if not house_enter.body_entered.is_connected(_on_house_enter_body_entered):
		house_enter.body_entered.connect(_on_house_enter_body_entered)
	if not house_enter.body_exited.is_connected(_on_house_enter_body_exited):
		house_enter.body_exited.connect(_on_house_enter_body_exited)
	if not grave_exit.body_entered.is_connected(_on_grave_exit_body_entered):
		grave_exit.body_entered.connect(_on_grave_exit_body_entered)
	if not key_area.body_entered.is_connected(_on_key_body_entered):
		key_area.body_entered.connect(_on_key_body_entered)
	if not key_area.body_exited.is_connected(_on_key_body_exited):
		key_area.body_exited.connect(_on_key_body_exited)
	if not grave_entry.body_entered.is_connected(_on_grave_entry_body_entered):
		grave_entry.body_entered.connect(_on_grave_entry_body_entered)

	# Phone trigger initially hidden/disabled
	phone_trigger.visible = false
	phone_trigger.monitoring = false
	if not phone_trigger.body_entered.is_connected(_on_phone_trigger_body_entered):
		phone_trigger.body_entered.connect(_on_phone_trigger_body_entered)
	
	key.visible = false
	key_area.monitoring = false
	key_area.set_deferred("monitorable", false)
	key_available = false
	
# === INPUT HANDLER ===
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return

	var target = player_danilo.current_npc
	if target == "":
		return

	# --- HOUSE ---
	if target == "house_enter" and player_danilo.can_interact:
		tip.visible = false
		if not house_interacted:
			player_danilo.can_interact = false
			await DialogueManager.show_dialogue_balloon(A_4S_2, "smallhut_lock")
			house_interacted = true
			enable_all_dirts()
			enable_phone_trigger()
			player_danilo.can_interact = true
			return

		if house_interacted and not key_collected:
			player_danilo.can_interact = false
			await DialogueManager.show_dialogue_balloon(A_4S_2, "no_key")
			player_danilo.can_interact = true
			
			return

		if key_collected:
			if hut_already_entered:
				player_danilo.can_interact = false
				await DialogueManager.show_dialogue_balloon(A_4S_2, "already_entered")
				player_danilo.can_interact = true
				return
			else:
				hut_already_entered = true
				ProgressManager.save_dialogue_shown("hut_already_entered")
				ProgressManager.set_house_enter_disabled(true)
				emit_signal("hut_entered")
				return

	# --- DIRT ---
	if dirt_unlocked and player_danilo.can_interact and dirt_areas.has(target) and dirt_sprites[target].visible:
		player_danilo.force_cannot_move = true
		tip.visible = false
		await dig_anim(dirt_areas[target])
		player_danilo.force_cannot_move = false		
		# hide and save
		dirt_sprites[target].visible = false
		ProgressManager.set_dirt_visible(target, false)

		if target == "dirt_5" and not key_collected:
	# Reveal the key after digging dirt_5
			key.visible = true
			mark.visible = true
			key_area.monitoring = true
			key_area.set_deferred("monitorable", true)
			key_available = true
			dirt_unlocked = false
			disable_all_dirts()  # disable all dirts after dirt_5 dug
			print("🗝️ Key revealed after digging dirt_5. All other dirts disabled.")
		else:
			await DialogueManager.show_dialogue_balloon(A_4S_2, dirt_dialogues[target])

	# --- KEY ---
	if key_available and player_danilo.can_interact and not key_collected and target == "key":
		player_danilo.force_cannot_move = true
		tip.visible = false
		key_collected = true
		ProgressManager.set_key_collected(true)
		mark.visible = false
		key.visible = false
		key_area.monitoring = false
		key_area.set_deferred("monitorable", false)
		await DialogueManager.show_dialogue_balloon(A_4S_2, "dirt_5")
		player_danilo.force_cannot_move = false
		emit_signal("key_found")
		interact_house_after_key()
		return

# === AREA EVENTS ===
func _on_grave_entry_body_entered(body: Node2D):
	if body.name != "player_danilo":
		return
	if grave_entry_triggered:
		return

	DialogueManager.show_dialogue_balloon(A_4S_2, "grave_entry")
	grave_entry_triggered = true
	if grave_entry.body_entered.is_connected(_on_grave_entry_body_entered):
		grave_entry.body_entered.disconnect(_on_grave_entry_body_entered)
	grave_entry.monitoring = false
	grave_entry.set_deferred("monitorable", false)
	ProgressManager.set_house_enter_disabled(true)

func _on_grave_exit_body_entered(body: Node2D):
	if body.name != "player_danilo":
		return

	print("➡️ Grave exit triggered — ending scene (local handler)")
	# Inform controller (preferred) to handle transition/save
	if get_tree().root.has_node("Controller"):
		var ctrl = get_tree().root.get_node("Controller")
		# call controller handler safely
		if ctrl.has_method("_on_grave_exit_triggered"):
			ctrl._on_grave_exit_triggered()
		else:
			# as a fallback, emit local signal so controller can connect if needed
			emit_signal("grave_exit_triggered")
	else:
		# If no controller present, still emit the local signal for other listeners
		emit_signal("grave_exit_triggered")

func _on_house_enter_body_entered(body: Node2D):
	if body.name == "player_danilo":
		player_danilo.current_npc = "house_enter"
		player_danilo.can_interact = true
		tip.visible = true

func _on_house_enter_body_exited(body: Node2D):
	if body.name == "player_danilo":
		player_danilo.current_npc = ""
		player_danilo.can_interact = false
		tip.visible = false

func _on_phone_trigger_body_entered(body: Node2D):
	if body.name != "player_danilo":
		return
	SignalBus.unknown_sender_unlocked = true
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

func enable_phone_trigger():
	phone_trigger.visible = true
	phone_trigger.monitoring = true
	phone_trigger.set_deferred("monitorable", true)
	print("📱 Phone trigger enabled.")

func _on_chat_opened(chat_name: String):
	if chat_name == "unknown_sender" and not unknown_sender_opened:
		unknown_sender_opened = true
		await DialogueManager.show_dialogue_balloon(A_4S_2, "unknown_sender_clue")
		print("phone opened")

func dig_anim(target_area: Area2D):
	var original_position = player_danilo.global_position
	player_danilo.animation_locked = true
	player_danilo.can_move = false
	# Move player to target for digging animation
	player_danilo.global_position = target_area.global_position
	if animated_sprite_2d:
		animated_sprite_2d.play("digging_up")
		await animated_sprite_2d.animation_finished
	else:
		# fallback wait so timing remains consistent
		await get_tree().create_timer(0.6).timeout
	await get_tree().create_timer(0.2).timeout
	player_danilo.global_position = original_position
	player_danilo.animation_locked = false
	player_danilo.can_move = true

func setup_dirt_connections():
	if dirt_connections_done:
		return
	dirt_connections_done = true
	for name in dirt_areas.keys():
		var area = dirt_areas[name]
		# connect entered
		var entered_cb = func(body):
			dirt_entered(body, name)
		var exited_cb = func(body):
			dirt_exited(body, name)
		# Use unique callables to avoid duplicate anonymous functions confusion
		if not area.body_entered.is_connected(entered_cb):
			area.body_entered.connect(entered_cb)
		if not area.body_exited.is_connected(exited_cb):
			area.body_exited.connect(exited_cb)
	print("✅ Dirt connections set.")

func dirt_entered(body: Node2D, name: String):
	if body.name != "player_danilo":
		return

	if dirt_sprites[name].visible and dirt_unlocked:
		player_danilo.current_npc = name
		player_danilo.can_interact = true
		tip.visible = true
	else:
		player_danilo.current_npc = ""
		player_danilo.can_interact = false
		tip.visible = false

func dirt_exited(body: Node2D, name: String):
	if body.name == "player_danilo":
		if not dirt_dug[name]:
			tip.visible = false
		if player_danilo.current_npc == name:
			player_danilo.current_npc = ""
			player_danilo.can_interact = false

func set_dirt_used(name: String, update_sprite: bool = true, update_controller: bool = true):
	if not dirt_dug.has(name):
		push_error("set_dirt_used called with invalid dirt name: %s" % name)
		return
	# mark locally
	dirt_dug[name] = true

	# === Update controller (global) state ===
	if update_controller and get_tree().root.has_node("Controller"):
		var ctrl = get_tree().root.get_node("Controller")
		if not "graveyard_state" in ctrl:
			ctrl.graveyard_state = {}
		if not "dirt_visible" in ctrl.graveyard_state:
			ctrl.graveyard_state["dirt_visible"] = {}
		ctrl.graveyard_state["dirt_visible"][name] = false  # hidden after digging

	# === Update local sprite and area ===
	if update_sprite and dirt_sprites.has(name):
		dirt_sprites[name].visible = false
		if dirt_areas.has(name):
			dirt_areas[name].monitoring = false
			dirt_areas[name].set_deferred("monitorable", false)
	print("DIRT '%s' dug and hidden." % name)

func disable_all_dirts():
	for area in dirt_areas.values():
		area.monitoring = false
		area.set_deferred("monitorable", false)
	dirt_unlocked = false   # ✅ assign, not compare
	print("dirt disabled")

func enable_all_dirts():
	for area in dirt_areas.values():
		area.monitoring = true
		area.set_deferred("monitorable", true)
	dirt_unlocked = true   # ✅ assign, not compare
	print("dirt enabled")

func _on_key_body_entered(body: Node2D):
	if body.name == "player_danilo" and not key_collected:
		key_available = true
		player_danilo.current_npc = "key"
		player_danilo.can_interact = true
		tip.visible = true
		mark.visible = false

func _on_key_body_exited(body: Node2D):
	if body.name == "player_danilo" and not key_collected:
		player_danilo.current_npc = ""
		player_danilo.can_interact = false
		tip.visible = false

func interact_house_after_key():
	house_enter.monitoring = true
	house_enter.set_deferred("monitorable", true)
	player_danilo.current_npc = "house_enter"
	player_danilo.can_interact = true
	tip.visible = false
	print("🏠 House interaction re-enabled after collecting key.")

func enable_grave_exit():
	grave_exit.monitoring = true
	grave_exit.set_deferred("monitorable", true)
	ProgressManager.set_grave_exit_enabled(true)
