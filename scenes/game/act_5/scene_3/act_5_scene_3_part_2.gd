extends Node2D

const A_5S_3 = preload("uid://dntq0tdotjt87")

@onready var wendy_area: Area2D = $wendy
@onready var npcwendy: CharacterBody2D = $"danilo_hometown/y-sorted-objects/wendy"
@onready var wendy: CharacterBody2D = $"danilo_hometown/y-sorted-objects/danilo_follow_mateo/wendy"
@onready var player_mateo: CharacterBody2D = $"danilo_hometown/y-sorted-objects/danilo_follow_mateo/player_mateo"

var wendy_is_following: bool =  false

func _ready() -> void:
	npcwendy.visible = false
	wendy.hide()
	$"danilo_hometown/y-sorted-objects/danilo_follow_mateo/player_mateo".last_direction = Vector2.DOWN
	
	wendy_area.body_entered.connect(_on_wendy_body_entered)
	
func _process(delta: float) -> void:
	print(player_mateo.velocity)

func _on_wendy_body_entered(body: Node2D)->void:
	if body.name == "player_mateo":
		wendy_is_following = true
		npcwendy.visible = true
		player_mateo.force_cannot_move = true
		await get_tree().create_timer(0.5).timeout
		DialogueManager.show_dialogue_balloon(A_5S_3, "wendy")
		wendy_area.queue_free()

func make_wendy_follow_mateo_and_danilo()->void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	npcwendy.visible = false
	wendy.show()
	
func _on_finish_body_entered(body: Node2D) -> void:
	if not wendy_is_following:
		return
	act_5_scene_3_done()

func act_5_scene_3_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_4"
	SignalBus.act_num_scene_num_done.emit("act_5", "scene_3", "res://scenes/game/act_5/scene_3/act_5_scene_4.tscn")
