extends Node2D

signal paper_done
signal hut_exit

const A_4S_2 = preload("res://dialogues/act_4/scene_2/a4s2.dialogue")
const GRAVEYARD = preload("res://scenes/game/act_4/scene_2/graveyard.tscn")

@onready var player_danilo: CharacterBody2D = $"y-sorted/player_danilo"
@onready var house_exit: Area2D =$Interactable/house_exit
@onready var tip: Sprite2D = $"y-sorted/player_danilo/tip_interact"
@onready var mark: Sprite2D = $"y-sorted/player_danilo/question"
@onready var phone_trigger: Area2D = $"Interactable/phone_trigger"
@onready var paper_5: Sprite2D = $"y-sorted/PAPER5/paper_5"
@onready var paper5_area: Area2D = $Interactable/P5
@onready var kusina: Area2D = $Interactable/Kusina
@onready var kwarto1: Area2D = $Interactable/Kwarto1
@onready var kwarto2: Area2D = $Interactable/Kwarto2
@onready var cr: Area2D = $Interactable/Cr
@onready var sala: Area2D = $Interactable/Sala
@onready var paper5_collsion: CollisionShape2D = $"y-sorted/PAPER5/CollisionShape2D"

@onready var paper_sprites= {
	"paper_1": $"y-sorted/PAPER1/paper_1",
	"paper_2": $"y-sorted/PAPER2/paper_2",
	"paper_3": $"y-sorted/PAPER3/paper_3",
	"paper_4": $"y-sorted/PAPER4/paper_4"
}

@onready var paper_areas = {
	"paper_1": $Interactable/p1,
	"paper_2": $Interactable/p2,
	"paper_3": $Interactable/p3,
	"paper_4": $Interactable/p4
}

@onready var paper_dialogue = {
	"paper_1": "paper_1",
	"paper_2": "paper_2",
	"paper_3": "paper_3",
	"paper_4": "paper_4"
}

var paper_found = { 
	"paper_1": false, 
	"paper_2": false, 
	"paper_3": false, 
	"paper_4": false,
	"paper_5": false
}

var can_interact_paper5: bool = false
var unknown_sender_opened: bool = false
var phone_showing: bool = false
var lock_screen_active: bool = false
var phone_main_active: bool = false
var chat_open: bool = false
var can_interact_papers: bool = false
var current_paper_name: String = ""

func _ready() -> void:
	tip.visible = false
	mark.visible = false
	paper5_collsion.disabled = false
	player_danilo.can_move = false
	DialogueManager.show_dialogue_balloon(A_4S_2, "house_entry")
	player_danilo.can_move = true
	
	paper5_area.body_entered.connect(_on_p5_body_entered)
	paper5_area.body_exited.connect(_on_p5_body_exited)
	
	phone_trigger.visible = false
	phone_trigger.monitoring = false
	phone_trigger.set_deferred("monitorable", false)
	phone_trigger.body_entered.connect(_on_phone_trigger_body_entered)
	
	for area in [kusina, kwarto1, kwarto2, cr, sala]:
		area.monitoring = false
		area.set_deferred("monitorable", false)
	
	for paper_name in paper_areas.keys():
		var area = paper_areas[paper_name]
		area.body_entered.connect(func(body):
			_on_paper_body_entered(paper_name, body))
		area.body_exited.connect(func(body):
			_on_paper_body_exited(paper_name, body))

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	# --- PAPER 5 INTERACTION ---
	if can_interact_paper5 and not paper_found["paper_5"]:
		_on_paper5_interacted()
		return

	# --- PAPERS 1-4 INTERACTION ---
	if can_interact_papers and current_paper_name != "" and not paper_found[current_paper_name]:
		_on_paper_interacted(current_paper_name)
		return

	# --- HOUSE EXIT INTERACTION ---
	if player_danilo.can_interact and player_danilo.current_npc == "house_exit":
		tip.visible = false
		player_danilo.can_interact = false
		player_danilo.current_npc = ""
		emit_signal("hut_exit")  
		return


func _on_paper5_interacted() -> void:
	paper_found["paper_5"] = true
	tip.visible = false
	mark.visible = false
	can_interact_paper5 = false
	player_danilo.can_move = false

	# Disable collision so area cannot be triggered again
	paper5_area.monitoring = false
	paper5_area.set_deferred("monitorable", false)
	paper5_collsion.disabled = true

	# Change sprite region
	paper_5.region_enabled = true
	paper_5.region_rect = Rect2(16.892, 0.089, 14.931, 15.911)

	# Play dialogue for paper_5
	await DialogueManager.show_dialogue_balloon(A_4S_2, "paper_5")
	enable_phone_trigger()
	player_danilo.can_move = true

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
		await DialogueManager.show_dialogue_balloon(A_4S_2, "unknown_sender_paper_clue")
		await get_tree().process_frame

		for area in [kusina, kwarto1, kwarto2, cr, sala]:
			area.monitoring = true
			area.set_deferred("monitorable", true)
		
		enable_papers_1_to_4()
		cr.body_entered.connect(_on_cr_body_entered)
		kwarto2.body_entered.connect(_on_kwarto_2_body_entered)
		sala.body_entered.connect(_on_sala_body_entered)
		kusina.body_entered.connect(_on_kusina_body_entered)
		kwarto1.body_entered.connect(_on_kwarto_1_body_entered)

func _on_paper_interacted(paper_name: String) -> void:
	paper_found[paper_name] = true
	tip.visible = false
	mark.visible = false
	can_interact_papers = false
	player_danilo.can_move = false

# Disable collision for this paper
	var area = paper_areas[paper_name]
	area.monitoring = false
	area.set_deferred("monitorable", false)

# Change sprite region like paper_5
	var sprite = paper_sprites[paper_name]
	sprite.region_enabled = true
	sprite.region_rect = Rect2(16.892, 0.089, 14.931, 15.911)

# Play dialogue
	await DialogueManager.show_dialogue_balloon(A_4S_2, paper_dialogue[paper_name])

# Check if all papers 1-4 are collected
	var all_collected = true
	for p in ["paper_1","paper_2","paper_3","paper_4"]:
		if not paper_found[p]:
			all_collected = false
			break

	if all_collected:
		await get_tree().create_timer(5).timeout
		await DialogueManager.show_dialogue_balloon(A_4S_2, "paper_found")
	# Enable house exit
		emit_signal("papers_done")
	
		house_exit.monitoring = true
		house_exit.set_deferred("monitorable", true)
		house_exit.body_entered.connect(_on_house_exit_entered)

		player_danilo.can_move = true

func enable_papers_1_to_4():
	for paper_name in paper_areas.keys():
		var area = paper_areas[paper_name]
	# Only enable if not yet collected
		if not paper_found[paper_name]:
			area.monitoring = true
			area.set_deferred("monitorable", true)

func _on_paper_body_entered(paper_name: String, body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	if paper_found[paper_name]:
		return
	tip.visible = true
	mark.visible = true
	can_interact_papers = true
	current_paper_name = paper_name
	player_danilo.set_meta("current_paper", paper_name)

func _on_paper_body_exited(paper_name: String, body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	tip.visible = false
	mark.visible = false
	can_interact_papers = false
	current_paper_name = ""
	player_danilo.set_meta("current_paper", null)
	
func _on_cr_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	DialogueManager.show_dialogue_balloon(A_4S_2, "enter_cr")
	await get_tree().process_frame
	cr.body_entered.disconnect(_on_cr_body_entered)

func _on_kwarto_2_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	DialogueManager.show_dialogue_balloon(A_4S_2, "enter_kwarto2")
	await get_tree().process_frame
	kwarto2.body_entered.disconnect(_on_kwarto_2_body_entered)

func _on_sala_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	DialogueManager.show_dialogue_balloon(A_4S_2, "enter_sala")
	await get_tree().process_frame
	sala.body_entered.disconnect(_on_sala_body_entered)

func _on_kusina_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	DialogueManager.show_dialogue_balloon(A_4S_2, "enter_kusina")
	await get_tree().process_frame
	kusina.body_entered.disconnect(_on_kusina_body_entered)

func _on_kwarto_1_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	DialogueManager.show_dialogue_balloon(A_4S_2, "enter_kwarto1")
	await get_tree().process_frame
	kwarto1.body_entered.disconnect(_on_kwarto_1_body_entered)

func _on_p5_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return

	# Only show tip if paper not yet collected
	if not paper_found["paper_5"]:
		tip.visible = true
		mark.visible = true
		can_interact_paper5 = true

func _on_p5_body_exited(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	# Hide tip/mark when leaving area
	tip.visible = false
	mark.visible = false
	can_interact_paper5 = false

func _on_house_exit_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	
	player_danilo.current_npc = "house_exit"
	player_danilo.can_interact = true
	tip.visible = true
