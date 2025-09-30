extends Node2D

const A_1S_2 = preload("res://dialogues/act_1/scene_2/a1s2.dialogue")
const DANILO_AND_WENDY = preload("res://scenes/characters/danilo_and_wendy.tscn")

const NPC_WENDY_ALONE = preload("res://scenes/characters/npc_wendy.tscn")
const PLAYER_DANILO_ALONE = preload("res://scenes/characters/player_danilo.tscn")
@onready var player_danilo: CharacterBody2D = $"NPC Y-SORT/wendy_and_danilo_holder/player_danilo"
@onready var wendy: CharacterBody2D = $"NPC Y-SORT/wendy_and_danilo_holder/wendy"
@onready var camera_2d: Camera2D = $Camera2D
@onready var npc_y_sort: Node2D = $"NPC Y-SORT"
@onready var wendy_and_danilo_holder: Node2D = $"NPC Y-SORT/wendy_and_danilo_holder"

@export var follow_distance: float = 40.0
@export var follow_speed: float = 80.0
@onready var wendy_pan_area: Area2D = $wendy_pan_area

var camera_panned_to_wendy: bool = false
var can_talk_to_wendy: bool = false

# Track which tables have been looked at
var looked_tables = {
	"table_1": false,
	"table_2": false,
	"table_3": false,
	"table_4": false
}

@onready var table_areas = {
	"table_1": $table_areas/area_table_1,
	"table_2": $table_areas/area_table_2,
	"table_3": $table_areas/area_table_3,
	"table_4": $table_areas/area_table_4
}

# OBJECTIVES
var scene_objectives = [
	{"ID": 1, "text": "Look around for Wendy."},
	{"ID": 2, "text": "Find an empty table."}
]

func _ready() -> void:
	if BgmManager:
		BgmManager.stop_music()

	Hud.show_objectives()
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	camera_2d.position = player_danilo.global_position
	
	SignalBus.in_npc.connect(interact_npc)
	SignalBus.out_npc.connect(interact_npc)
	
	# Connect all table areas dynamically
	setup_table_connections()

func _process(delta: float) -> void:
	print(player_danilo.current_npc)
	if not camera_panned_to_wendy:
		camera_2d.position = player_danilo.global_position

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
		
	if not player_danilo.can_interact:
		return
	
	var current_npc = player_danilo.current_npc
	
	# Handle Wendy interaction
	if current_npc == "wendy" and can_talk_to_wendy:
		play_dialog(current_npc)
		npc_face_player(wendy, player_danilo.global_position)
		return
	
	# Handle table interactions
	if current_npc in table_areas.keys():
		play_dialog(current_npc)

func setup_table_connections() -> void:
	for table_name in table_areas.keys():
		var area = table_areas[table_name]
		area.body_entered.connect(func(body: Node2D): table_entered(body, table_name))
		area.body_exited.connect(func(body: Node2D): table_exited(body, table_name))

func pan_camera_to_wendy() -> void:
	player_danilo.animation_locked = true
	player_danilo.can_move = false
	var start_position = player_danilo.global_position
	var wendy_position = wendy.global_position
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(camera_2d, "position", wendy_position, 1.0)
	tween.tween_callback(func(): print("Camera reached Wendy"))
	tween.tween_interval(1.0)
	tween.tween_property(camera_2d, "position", start_position, 1.0)
	tween.tween_callback(func(): print("Camera back to player"))

	await tween.finished

	camera_panned_to_wendy = false
	print("Camera pan sequence complete")
	player_danilo.animation_locked = false
	player_danilo.can_move = true
	wendy_pan_area.monitoring = false

func wendy_follow() -> void:
	ObjectiveManager.add_objective(scene_objectives[1]['ID'], scene_objectives[1]['text'])
	var d_and_w = DANILO_AND_WENDY.instantiate()
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	
	var holder = wendy_and_danilo_holder
	
	for node in holder.get_children():
		node.queue_free()
	
	await get_tree().process_frame
	
	holder.add_child(d_and_w)
	
	player_danilo = holder.get_node("danilo_and_wendy/player_danilo")
	wendy = holder.get_node("danilo_and_wendy/wendy")

func table_entered(body: Node2D, table_name: String) -> void:
	if body.name != "player_danilo":
		return
	
	# Only allow interaction if table hasn't been "used up" by dialogue
	if not looked_tables[table_name]:
		SignalBus.in_npc.emit(table_name)
		print("in " + table_name)
		player_danilo.can_interact = true

func table_exited(body: Node2D, table_name: String) -> void:
	if body.name != "player_danilo":
		return
		
	SignalBus.out_npc.emit(table_name)

func play_dialog(npc_name: String) -> void:
	match npc_name:
		"wendy":
			DialogueManager.show_dialogue_balloon(A_1S_2, "wendy_start")
		"table_1":
			print("dialoging table 1")
			DialogueManager.show_dialogue_balloon(A_1S_2, "pick_table_1")
		"table_2":
			print("dialoging table 2")
			DialogueManager.show_dialogue_balloon(A_1S_2, "pick_table_2")
		"table_3":
			print("dialoging table 3")
			DialogueManager.show_dialogue_balloon(A_1S_2, "pick_table_3")
		"table_4":
			print("dialoging table 4")
			DialogueManager.show_dialogue_balloon(A_1S_2, "pick_table_4")

# Function to be called from dialogue resource to disable table interaction
func set_table_used(table_name: String) -> void:
	looked_tables[table_name] = true
	print(table_name + " is now used and can't be interacted with again")
	
	# Optionally remove the area entirely if you want
	if table_areas.has(table_name):
		table_areas[table_name].queue_free()

func interact_npc(npc_name: String) -> void:
	if npc_name == "wendy":
		can_talk_to_wendy = !can_talk_to_wendy

func npc_face_player(npc: CharacterBody2D, player_position: Vector2) -> void:
	var direction_to_player = player_position - npc.global_position
	
	# Use the axis with the larger absolute difference
	if abs(direction_to_player.x) > abs(direction_to_player.y):
		npc.direction = Vector2.RIGHT if direction_to_player.x > 0 else Vector2.LEFT
	else:
		npc.direction = Vector2.DOWN if direction_to_player.y > 0 else Vector2.UP
	
	await get_tree().process_frame
	npc.direction = Vector2.ZERO

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo" and not camera_panned_to_wendy:
		ObjectiveManager.complete_objective(scene_objectives[0]["ID"]);
		print("play camera")
		camera_panned_to_wendy = true
		await pan_camera_to_wendy()

func wendy_unfollow() -> void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	
	var holder = wendy_and_danilo_holder
	for node in holder.get_children():
		node.queue_free()
	
	var danilo_alone = PLAYER_DANILO_ALONE.instantiate()
	var wendy_alone = NPC_WENDY_ALONE.instantiate()
	holder.add_child(danilo_alone)
	holder.add_child(wendy_alone)
	
	player_danilo = danilo_alone
	wendy = wendy_alone
	
	# Wait one frame so _ready() finishes
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	player_danilo.can_move = false
	player_danilo.animated_sprite_2d.play("idle_right")
	
	player_danilo.get_child(1).disabled = true; #this is collission child of player danilo node, disable d2 para hindi manginig yung sprite
	wendy.get_child(1).disabled = true;
	
	player_danilo.position = $danilo_table_spawn.global_position
	wendy.position = $wendy_table_spawn.global_position
	
	camera_2d.position = player_danilo.global_position
	camera_2d.make_current()

	DialogueManager.show_dialogue_balloon(A_1S_2, "table_conversation");
