extends Node2D

# PRELOADS
const A_1S_1 = preload("res://dialogues/act_1/scene_1/a1s1.dialogue");

# NODES
@onready var storm_animation: AnimationPlayer = $storm_animation;
@onready var camera_animation: AnimationPlayer = $camera_animation;
@onready var player_danilo: CharacterBody2D = $player_danilo;
@onready var tip_interact: Sprite2D = $player_danilo/tip_interact;
@onready var animated_sprite_2d: AnimatedSprite2D = $player_danilo/AnimatedSprite2D;
@onready var marker_2d: Marker2D = $Marker2D;
@onready var water_glass: Sprite2D = $water_glass;
@onready var water_area: Area2D = $water_glass/water_area;
@onready var tension_animation: AnimationPlayer = $tension_animation
@onready var bed_area: Area2D = $bed_area
@onready var sleep_marker: Marker2D = $sleep_marker


# OBJECTIVES
var scene_objectives = [
	{"ID": 1, "text": "Drink Water"},
	{"ID": 2, "text": "Check Phone Time"},
	{"ID" : 3, "text" : "Go Back to Bed"}
]

# STATES
var inside_water : bool = false;
var inside_bed : bool = false;
var can_interact : bool = false;

func _ready() -> void:
	
	DialogueManager.dialogue_started.connect(_on_dialogue_start);
	DialogueManager.dialogue_ended.connect(_on_dialogue_finish);
	
	camera_animation.play("intro_pan");
	_intro_anim();

func _on_dialogue_start(_resource):
	can_interact = false;

func _on_dialogue_finish(_resource):
	can_interact = true;

# scene animations
func _intro_anim() -> void:
	var playerNode = get_node("player_danilo");
	player_danilo.animation_locked = true;
	playerNode.last_direction = Vector2.RIGHT;
	
	$player_danilo/CollisionShape2D.disabled = true; # turn off muna para hindi manginig si danilo habang natutulog
	playerNode.can_move = false;
	
	animated_sprite_2d.play("sleep"); # amimir muna sa danilo nang 15 seconds
	await get_tree().create_timer(10).timeout;
	
	animated_sprite_2d.play("woken");# tas magigising sya dito, maganda kung may sfx nang thunder
	await get_tree().create_timer(2).timeout;
	
	playerNode.position = marker_2d.position; # spawn si danilo sa marker
	
	animated_sprite_2d.play("idle_right"); # direction pag ka gising
	await get_tree().create_timer(2).timeout;
	
	playerNode.last_direction = Vector2.UP; # tingin sya sa bintana
	animated_sprite_2d.play("idle_up");
	$player_danilo/CollisionShape2D.disabled = false; # on na collision since nasa safe space na sya
	player_danilo.animation_locked = false  # give control back to player script
	playerNode.can_move = true;
	
	DialogueManager.show_dialogue_balloon(A_1S_1, "start");
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"]);

func drink_water_anim() -> void:
	player_danilo.animation_locked = true;
	player_danilo.can_move = false;
	water_glass.visible = false;
	
	animated_sprite_2d.play("drinking_water");
	await animated_sprite_2d.animation_finished;
	
	var glass_region := water_glass.texture as AtlasTexture;
	glass_region.region.position = Vector2(16, 0)
	water_area.monitoring = false;
	
	water_glass.visible = true;
	player_danilo.can_move = true;
	player_danilo.animation_locked = false;
	SignalBus.drank_water.emit();
	ObjectiveManager.complete_objective(1);

func tension_in_anim() -> void:
	tension_animation.play("tension_in");
	await tension_animation.animation_finished;
	tension_anim();

func tension_anim() -> void:
	tension_animation.play("tension");
	
func tension_out_anim() -> void:
	tension_animation.play("tension_out");

func _go_to_sleep() -> void: 
	player_danilo.animation_locked = true;
	$player_danilo/CollisionShape2D.disabled = true;
	player_danilo.position  = sleep_marker.position; 
	animated_sprite_2d.play("sleep"); 
	player_danilo.can_move = false;
	ObjectiveManager.complete_objective(3)

# interactions
func _on_water_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		tip_interact.visible = true;
		inside_water = true;

func _on_water_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		tip_interact.visible = false;
		inside_water = false;


func _on_bed_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		tip_interact.visible = true;
		inside_bed = true;
	
func _on_bed_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		tip_interact.visible = false;
		inside_bed = false;

func activate_bed() -> void:
	bed_area.monitoring = true;
# input
func _input(event: InputEvent) -> void:
	if event.is_action("interact") and can_interact and inside_water:
		DialogueManager.show_dialogue_balloon(A_1S_1, "water");
		return;
	
	if event.is_action("interact") and can_interact and inside_bed:
		_go_to_sleep();
		bed_area.monitoring = false;
func add_notification() -> void:
	const SCHED_ICON = preload("res://assets/HUD/sched_icon.png")
	Hud.get_node("Control/phone/MarginContainer/lock_screen").add_notification(SCHED_ICON, "Reminders", "Day of Mateo's disapearnce");
