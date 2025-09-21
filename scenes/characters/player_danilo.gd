extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var player_danilo: CharacterBody2D = $"."
@onready var marker_2d: Marker2D = $"../Marker2D"

@export var SPEED : float = 80.0
var last_direction : Vector2 = Vector2.DOWN; #to play idle animation
var is_sleeping : bool = true;
var can_move : bool = true; # toggle at start and end of dialogue

func _physics_process(delta: float) -> void:
	if not can_move:  # prevent movement during dialogue
		velocity = Vector2.ZERO;
		move_and_slide();
		return;
	
	if not is_sleeping:
		var direction = _get_direction();
		_play_animation(direction);
		
		velocity = direction.normalized() * SPEED;
		
		move_and_slide();


func _get_direction ()-> Vector2: # get direction from inputs
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

func _play_animation(direction: Vector2) -> void: # play animations based on directions walk/idle
	
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
