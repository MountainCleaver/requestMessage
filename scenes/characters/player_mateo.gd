extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var tip_interact: Sprite2D = $tip_interact

@export var SPEED: float = 80.0
@export var RUNNING_SPEED: float = 200.0

var joystick: VirtualJoystick = null
@onready var action_buttons: Node = get_node("../CanvasLayer/ActionButtons")

var joystick_direction: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.DOWN
var can_move: bool = true
var animation_locked: bool = false

var is_running: bool = false
var can_interact: bool = false

var real_velocity: Vector2 = Vector2.ZERO
var current_npc: String = ""
var force_cannot_move: bool = false


func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_start)
	DialogueManager.dialogue_ended.connect(_on_dialogue_finish)
	SignalBus.in_npc.connect(show_tip)
	SignalBus.out_npc.connect(hide_tip)

	_joystick_init()
	_buttons_init()


func _joystick_init():
	joystick = find_node_recursive(get_tree().get_current_scene(), "VirtualJoystick") as VirtualJoystick
	if joystick:
		joystick.analogic_changed.connect(_on_joystick_moved)


func _buttons_init():
	if action_buttons:
		action_buttons.connect("run_pressed", Callable(self, "_on_run_button"))
		action_buttons.connect("map_pressed", Callable(self, "_on_map_button"))
		action_buttons.connect("interact_pressed", Callable(self, "_on_interact_button"))


func _physics_process(delta: float) -> void:

	if not can_player_move():
		velocity = Vector2.ZERO
		move_and_slide()
		if not animation_locked:
			_play_animation(Vector2.ZERO)
		return

	var direction = _get_direction()

	# Override with virtual joystick
	if joystick_direction.length() > 0.05:
		direction = _joystick_to_cardinal(joystick_direction)

	var current_speed = RUNNING_SPEED if is_running else SPEED
	velocity = direction * current_speed

	move_and_slide()

	if animation_locked:
		return

	real_velocity = get_real_velocity()

	if real_velocity.length() > 0.1:
		if direction != Vector2.ZERO:
			last_direction = direction
		_play_animation(direction)
	else:
		_play_animation(Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if not can_player_move():
		return

	if event.is_action_pressed("run"):
		is_running = true
	elif event.is_action_released("run"):
		is_running = false


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
	if direction == Vector2.ZERO:
		match last_direction:
			Vector2.RIGHT: animated_sprite_2d.play("idle_right")
			Vector2.LEFT: animated_sprite_2d.play("idle_left")
			Vector2.DOWN: animated_sprite_2d.play("idle_down")
			Vector2.UP: animated_sprite_2d.play("idle_up")
	else:
		match direction:
			Vector2.RIGHT: animated_sprite_2d.play("walk_right")
			Vector2.LEFT: animated_sprite_2d.play("walk_left")
			Vector2.DOWN: animated_sprite_2d.play("walk_down")
			Vector2.UP: animated_sprite_2d.play("walk_up")


func _on_dialogue_start(_resource):
	can_move = false
	can_interact = false
	is_running = false


func _on_dialogue_finish(_resource):
	can_move = true
	can_interact = true
	is_running = Input.is_action_pressed("run")


# ==== VIRTUAL JOYSTICK ====

func _on_joystick_moved(value: Vector2, _d, _a, _cw, _ccw):
	joystick_direction = value


func _joystick_to_cardinal(dir: Vector2) -> Vector2:
	if dir.length() < 0.1:
		return Vector2.ZERO

	if abs(dir.x) > abs(dir.y):
		return Vector2(sign(dir.x), 0)
	else:
		return Vector2(0, sign(dir.y))


# ==== ACTION BUTTONS ====

func _on_run_button(is_pressed: bool):
	is_running = is_pressed


func _on_map_button():
	force_cannot_move = not force_cannot_move


func _on_interact_button():
	if can_interact and current_npc != "":
		print("Interacting with ", current_npc)


# ==== NPC TIP ====

func show_tip(npc_name: String) -> void:
	tip_interact.visible = true
	can_interact = true
	current_npc = npc_name


func hide_tip(_npc_name: String) -> void:
	tip_interact.visible = false
	can_interact = false
	current_npc = ""


func can_player_move() -> bool:
	return can_move and not force_cannot_move


# ======= FIND NODE RECURSIVE (same as danilo) =======

func find_node_recursive(root: Node, name: String) -> Node:
	if root.name == name:
		return root
	for child in root.get_children():
		var found = find_node_recursive(child, name)
		if found:
			return found
	return null
