extends Node2D

@onready var npc_danilo: CharacterBody2D = $"danilo_hometown_house/y-sorted/npc_danilo"
@onready var npc_mira: CharacterBody2D = $"danilo_hometown_house/y-sorted/npc_mira"
@onready var player_mateo: CharacterBody2D = $"danilo_hometown_house/y-sorted/player_mateo"
@onready var area_2d: Area2D = $"danilo_hometown_house/y-sorted/npc_danilo/Area2D"
@onready var tip_interact: Sprite2D = $"danilo_hometown_house/y-sorted/player_mateo/tip_interact"
@onready var animated_sprite_2d: AnimatedSprite2D = $"danilo_hometown_house/y-sorted/npc_danilo/AnimatedSprite2D"
@onready var marker_2d: Marker2D = $"danilo_hometown_house/y-sorted/Marker2D"
@onready var marker_2d_2: Marker2D = $"danilo_hometown_house/y-sorted/Marker2D2"

@onready var sfx_washing: AudioStreamPlayer = $SFX_WASHING

var A_5S_3: Resource

var interacting_with : String = ""
var can_interact : bool = true

func _ready() -> void:
	sfx_washing.play()
	_load_dialogue()
	$"danilo_hometown_house/y-sorted/npc_danilo/AnimatedSprite2D".play("idle_left")
	$"danilo_hometown_house/y-sorted/npc_mira/AnimatedSprite2D".play("idle_up")
	player_mateo.last_direction = Vector2.UP
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	area_2d.body_exited.connect(_on_area_2d_body_exit)

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_5/scene_3/a5s3_en.dialogue"
	else:
		path = "res://dialogues/act_5/scene_3/a5s3.dialogue"
	
	A_5S_3 = load(path)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if not can_interact:
			return
		if interacting_with == "npc_danilo":
			can_interact = false
			player_mateo.force_cannot_move = true
			DialogueManager.show_dialogue_balloon(A_5S_3, "inside_house")
			area_2d.queue_free() # remove after dialogue

func _on_area_2d_body_entered(body: Node2D)->void:
	if body.name == "player_mateo":
		interacting_with = "npc_danilo"
		tip_interact.visible = true

func _on_area_2d_body_exit(body: Node2D)->void:
	if body.name == "player_mateo":
		interacting_with = ""
		tip_interact.visible = false

func _paalam_kay_mama()->void:
	sfx_washing.stop()
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	$"danilo_hometown_house/y-sorted/npc_danilo/AnimatedSprite2D".play("idle_up")
	$"danilo_hometown_house/y-sorted/npc_mira/AnimatedSprite2D".play("idle_down")
	player_mateo.last_direction = Vector2.UP
	player_mateo.global_position = marker_2d.global_position
	npc_danilo.global_position = marker_2d_2.global_position
	DialogueManager.show_dialogue_balloon(A_5S_3, "paalam")
	







func lalabas_ng_bahay()->void:
	SignalBus.next_scene.emit("res://scenes/game/act_5/scene_3/act_5_scene_3_part_2.tscn")
