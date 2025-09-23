extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var SPEED: float = 80.0;
@export var RUNNING_SPEED : float = 200.0;
var last_direction: Vector2 = Vector2.DOWN # to play idle animation
var can_move: bool = true # toggle at start and end of dialogue
var animation_locked: bool = false

var is_running : bool = false;


func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_start)
	DialogueManager.dialogue_ended.connect(_on_dialogue_finish)

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		if not animation_locked:
			_play_animation(Vector2.ZERO)
		return
	
	var direction = _get_direction()
	
	if is_running:
		velocity = direction.normalized() * RUNNING_SPEED
	else:
		velocity = direction.normalized() * SPEED
	
	move_and_slide()

	if animation_locked:
		return # don't override animations during cutscenes/scripted events

	var real_velocity = get_real_velocity()

	if real_velocity.length() > 0.1:
		if direction != Vector2.ZERO:
			last_direction = direction
		_play_animation(direction)
	else:
		_play_animation(Vector2.ZERO)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("run"):
		is_running = true;
	elif event.is_action_released("run"):
		is_running = false;
	

func _get_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO

	if Input.is_action_pressed("arrow_left"):
		direction.x = -1
	elif Input.is_action_pressed("arrow_right"):
		direction.x = 1
	elif Input.is_action_pressed("arrow_up"):
		direction.y = -1
	elif Input.is_action_pressed("arrow_down"):
		direction.y = 1

	return direction

func _play_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO or not can_move:
		match last_direction:
			Vector2.RIGHT:
				animated_sprite_2d.play("idle_right")
			Vector2.LEFT:
				animated_sprite_2d.play("idle_left")
			Vector2.DOWN:
				animated_sprite_2d.play("idle_down")
			Vector2.UP:
				animated_sprite_2d.play("idle_up")
	else:
		match direction:
			Vector2.RIGHT:
				animated_sprite_2d.play("walk_right")
			Vector2.LEFT:
				animated_sprite_2d.play("walk_left")
			Vector2.DOWN:
				animated_sprite_2d.play("walk_down")
			Vector2.UP:
				animated_sprite_2d.play("walk_up")

func _on_dialogue_start(_resource):
	can_move = false

func _on_dialogue_finish(_resource):
	can_move = true
