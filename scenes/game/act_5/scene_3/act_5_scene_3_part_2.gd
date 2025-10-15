extends Node2D

const A_5S_3 = preload("uid://dntq0tdotjt87")

@onready var player_mateo: CharacterBody2D = $"danilo_hometown/y-sorted-objects/player_mateo"
@onready var npc_danilo: CharacterBody2D = $"danilo_hometown/y-sorted-objects/npc_danilo"
@onready var wendy: Area2D = $wendy
@onready var npcwendy: CharacterBody2D = $"danilo_hometown/y-sorted-objects/wendy"

func _ready() -> void:
	npcwendy.visible = false
	$"danilo_hometown/y-sorted-objects/npc_danilo/AnimatedSprite2D".play("idle_down")
	player_mateo.last_direction = Vector2.DOWN
	
	wendy.body_entered.connect(_on_wendy_body_entered)

func _on_wendy_body_entered(body: Node2D)->void:
	if body.name == "player_mateo":
		npcwendy.visible = true
		wendy.queue_free()
		DialogueManager.show_dialogue_balloon(A_5S_3, "wendy")
		_all_three_walking_together()

func _all_three_walking_together()->void:
	# I have a TransitionFade.transition(), await SignalBus.transition_finished() you can use
	pass


func _on_finish_body_entered(body: Node2D) -> void:
	act_5_scene_3_done()

func act_5_scene_3_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_4"
	SignalBus.act_num_scene_num_done.emit("act_5", "scene_3", "res://scenes/game/act_5/scene_3/act_5_scene_4.tscn")
