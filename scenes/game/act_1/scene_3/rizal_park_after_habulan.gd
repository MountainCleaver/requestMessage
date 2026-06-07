extends Node2D
var A_1S_3: Resource

@onready var player_danilo: CharacterBody2D = $"NPC Y-SORT/wendy_and_danilo_holder/player_danilo"
@onready var wendy: CharacterBody2D = $"NPC Y-SORT/wendy_and_danilo_holder/wendy"
@onready var danilo_collision_shape_2d: CollisionShape2D = $"NPC Y-SORT/wendy_and_danilo_holder/player_danilo/CollisionShape2D"
@onready var wendy_collision_shape_2d: CollisionShape2D = $"NPC Y-SORT/wendy_and_danilo_holder/wendy/CollisionShape2D"
@onready var camera_2d: Camera2D = $Camera2D

var wendy_gone : bool = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FlashlightManager.set_current_scene("act_1", "scene_3")
	FlashlightManager.disable_flashlights()
	_load_dialogue()
	danilo_collision_shape_2d.disabled = true;
	wendy_collision_shape_2d.disabled = true;
	
	DialogueManager.show_dialogue_balloon(A_1S_3, "start");
	
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_1/scene_3/a1s3_en.dialogue"
	else:
		path = "res://dialogues/act_1/scene_3/a1s3.dialogue"
	
	A_1S_3 = load(path)
	
func _process(delta: float) -> void:
	if wendy_gone:
		camera_2d.position = player_danilo.global_position;

func _input(event: InputEvent) -> void:
	if event.is_action("interact") and player_danilo.current_npc == "jeep" and player_danilo.can_interact:
		DialogueManager.show_dialogue_balloon(A_1S_3, "jeep")

func re_enable_collisions () -> void:
	danilo_collision_shape_2d.disabled = false;
	wendy_collision_shape_2d.disabled = false;

func _leave_the_park() -> void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	
	DialogueManager.show_dialogue_balloon(A_1S_3, "pauwi");

func wendy_walk_away() -> void:
	player_danilo.force_cannot_move = true;
	wendy.direction = Vector2.DOWN;


func _on_wendy_turn_right_body_entered(body: Node2D) -> void:
	if body.name == "wendy":
		wendy.direction = Vector2.RIGHT;


func _on_wendy_vanish_body_entered(body: Node2D) -> void:
	if body.name == "wendy":
		player_danilo.force_cannot_move = false;
		wendy.queue_free()
		wendy_gone = true;

func scene_3_done () -> void:
	print("SCENE 3 FCKING DONE")
	ObjectiveManager.complete_objective(1);
	await get_tree().process_frame
	Hud.hide_objectives() 
	
	SaveManager.game_save.current_act = "act_1"
	SaveManager.game_save.current_scene = "scene_3" # badly named I admit. this is for the 'continue' part in main menu
	SaveManager.save_game()
	SignalBus.act_num_scene_num_done.emit("act_1", "scene_3", "res://scenes/game/act_1/scene_4/act_1_scene_4.tscn") # caught in save manager
	Hud.clear_objectives();


func _on_jeep_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("jeep")

func _on_jeep_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("jeep")
		
