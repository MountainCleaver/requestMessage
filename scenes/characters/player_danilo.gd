extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var player_danilo: CharacterBody2D = $"."
@onready var marker_2d: Marker2D = $"../Marker2D"
@onready var camera_animation: AnimationPlayer = $"../camera_animation"

@export var SPEED : float = 150.0
var last_direction : Vector2 = Vector2.DOWN;
var is_sleeping : bool = true;

func _ready() -> void:
	camera_animation.play("intro_pan");
	_play_sleep();

func _physics_process(delta: float) -> void:
	
	
	if not is_sleeping:
		var direction = _get_direction();
		_play_animation(direction);
		
		velocity = direction.normalized() * SPEED;
		
		move_and_slide();


func _get_direction ()-> Vector2:
	var direction : Vector2 = Vector2.ZERO;
	
	if Input.is_action_pressed("arrow_left"):
		direction.x = -1
	elif Input.is_action_pressed("arrow_right"):
		direction.x = 1
	elif Input.is_action_pressed("arrow_up"):
		direction.y = -1
	elif Input.is_action_pressed("arrow_down"):
		direction.y = 1
	
	if direction != Vector2.ZERO:
		last_direction = direction;
		
	return direction;

func _play_animation(direction: Vector2) -> void:
	
	if direction == Vector2.ZERO:
		match last_direction:
			Vector2.RIGHT:
				animated_sprite_2d.play("idle_right");
			Vector2.LEFT:
				animated_sprite_2d.play("idle_left");
			Vector2.DOWN:
				animated_sprite_2d.play("idle_down");
			Vector2.UP:
				animated_sprite_2d.play("idle_up");
	else:
		match direction:
			Vector2.RIGHT:
				animated_sprite_2d.play("walk_right");
			Vector2.LEFT:
				animated_sprite_2d.play("walk_left");
			Vector2.DOWN:
				animated_sprite_2d.play("walk_down");
			Vector2.UP:
				animated_sprite_2d.play("walk_up");

func _play_sleep():
	collision_shape_2d.disabled = true;
	animated_sprite_2d.play("sleep");
	
	var timer = get_tree().create_timer(15);
	await timer.timeout;
	
	animated_sprite_2d.play("idle_down");
	collision_shape_2d.disabled = false;
	is_sleeping = false;
	
	player_danilo.position = marker_2d.position;
