extends Node2D

@onready var storm_animation: AnimationPlayer = $storm_animation
@onready var camera_animation: AnimationPlayer = $camera_animation

@onready var player_danilo: CharacterBody2D = $player_danilo;
@onready var tip_interact: Sprite2D = $player_danilo/tip_interact;
@onready var animated_sprite_2d: AnimatedSprite2D = $player_danilo/AnimatedSprite2D

@onready var marker_2d: Marker2D = $Marker2D

@onready var water_glass: Sprite2D = $water_glass
@onready var water_area: Area2D = $water_glass/water_area


#flags
var drink_water_after_dialogue: bool = false;

const A_1S_1 = preload("res://dialogues/act_1/scene_1/a1s1.dialogue");
var can_interact: bool = true;
var inside_water : bool = false;
var sscene_objectives = [
	"Drink water",
	"Check Phone Time"
];

var scene_objectives = [
	{"id": 1, "text": "Drink water"},
	{"id": 2, "text": "Check Phone Time"}
]


var current_objective : int = 0;

func _ready() -> void:
	SignalBus.looked_window.connect(_dialog_player);
	SignalBus.looked_window.connect(_obj_get_water);
	
	SignalBus.drank_water.connect(_done_obj_get_water);
	
	DialogueManager.dialogue_started.connect(_on_dialogue_start);
	DialogueManager.dialogue_ended.connect(_on_dialogue_finish);
	
	camera_animation.play("intro_pan")
	storm_animation.play("storm")

	_intro_anim();

func _process(delta: float) -> void:
	print(current_objective);

func _on_dialogue_start(_resource):
	var playerNode = get_node("player_danilo");
	playerNode.can_move = false;
	can_interact = false;

func _on_dialogue_finish(_resource):
	var playerNode = get_node("player_danilo");
	playerNode.can_move = true;
	can_interact = true;
	
	if drink_water_after_dialogue:
		drink_water_anim();
		drink_water_after_dialogue = false;

func _dialog_player():
	match current_objective:
		0:
			_dialog_play(A_1S_1, "start");
			current_objective += 1;
		1: 
			_dialog_play(A_1S_1, "phone_time");
			current_objective += 1;

func _dialog_play(resource: DialogueResource, part: String)->void:
	DialogueManager.show_dialogue_balloon(resource, part);


#interactions
func _input(event: InputEvent) -> void:
	if event.is_action("interact") and can_interact and inside_water:
		_dialog_play(A_1S_1, "water_test");
		drink_water_after_dialogue = true;

func _on_water_area_body_entered(body: Node2D) -> void:
	tip_interact.visible = true;
	inside_water = true;

func _on_water_area_body_exited(body: Node2D) -> void:
	tip_interact.visible = false;
	inside_water = false;


#story animations:
func _intro_anim() -> void:
	var playerNode = get_node("player_danilo");
	playerNode.last_direction = Vector2.RIGHT;
	
	$player_danilo/CollisionShape2D.disabled = true; # turn off muna para hindi manginig si danilo habang natutulog
	playerNode.can_move = false;
	
	animated_sprite_2d.play("sleep"); # amimir muna sa danilo nang 15 seconds
	await get_tree().create_timer(2).timeout;
	
	animated_sprite_2d.play("woken");# tas magigising sya dito, maganda kung may sfx nang thunder
	await get_tree().create_timer(2).timeout;
	
	playerNode.position = marker_2d.position; # spawn si danilo sa marker
	
	animated_sprite_2d.play("idle_right"); # direction pag ka gising
	await get_tree().create_timer(2).timeout;
	
	playerNode.last_direction = Vector2.UP; # tingin sya sa bintana
	animated_sprite_2d.play("idle_up");
	$player_danilo/CollisionShape2D.disabled = false; # on na collision since nasa safe space na sya
	
	playerNode.is_sleeping = false; 
	playerNode.can_move = true;
	SignalBus.looked_window.emit(); # since naka tingin na sya sa bintana, signal na to para iplay pinaka unang dialogue lines tas add ng unang objective sa objective panel

func drink_water_anim() -> void:
	
	var playerNode = get_node("player_danilo");
	playerNode.can_move = false;
	water_glass.visible = false;
	
	animated_sprite_2d.play("drinking_water");
	await animated_sprite_2d.animation_finished;
	
	var glass_region := water_glass.texture as AtlasTexture;
	glass_region.region.position = Vector2(16, 0)
	water_area.monitoring = false;
	# water_glass.this sprite uses an atlas that contains 2 images of flasses, one empty and full. I want to replace it with empty glass after drink animation
	water_glass.visible = true;
	playerNode.can_move = true;
	
	SignalBus.drank_water.emit();


# objecticves
func _obj_get_water():
	Hud.new_objective(scene_objectives[0]["id"], scene_objectives[0]["text"]);
func _done_obj_get_water():
	Hud.done_objective(scene_objectives[0]["id"], scene_objectives[0]["text"]);
