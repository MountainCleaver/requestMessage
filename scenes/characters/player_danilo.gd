extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var tip_interact: Sprite2D = $tip_interact

@onready var real_flashlight: PointLight2D = $real_flashlight
@onready var phone_flashlight: PointLight2D = $phone_flashlight
@onready var sfx_flashlight: AudioStreamPlayer = $sfx_flashlight

@export var SPEED: float = 80.0
@export var RUNNING_SPEED: float = 200.0
var last_direction: Vector2 = Vector2.DOWN
var can_move: bool = true
var animation_locked: bool = false

var is_running: bool = false
var can_interact: bool = false

var real_velocity: Vector2 = Vector2.ZERO
var current_npc: String = ""

var force_cannot_move: bool = false

# Wind variables
var wind_force: Vector2 = Vector2.ZERO
var is_in_wind: bool = false
var wind_source: Node2D = null

@export var wind_check_length: float = 10.0
@export var wind_block_mask: int = 1 << 0 

# NEW: Track input priority for non-diagonal movement
var input_priority: Array[String] = []

func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_start)
	DialogueManager.dialogue_ended.connect(_on_dialogue_finish)
	SignalBus.in_npc.connect(show_tip)
	SignalBus.out_npc.connect(hide_tip)
	SignalBus.map_toggled.connect(_on_map_toggled)
	
	# Initialize FlashlightManager
	FlashlightManager.init(real_flashlight, phone_flashlight)

func _physics_process(delta: float) -> void:
	# Block movement if the player can't move
	if not can_player_move():
		velocity = Vector2.ZERO
		move_and_slide()
		is_running = Input.is_action_pressed("run")
		if not animation_locked:
			_play_animation(Vector2.ZERO)
		return


	var direction = _get_direction()
	if can_player_move():
		is_running = Input.is_action_pressed("run")
		
	# Apply speed based on run state
	var current_speed = SPEED
	if is_running:
		current_speed = RUNNING_SPEED

	velocity = direction.normalized() * current_speed

	# Apply wind effects
	_apply_wind_effects()

	move_and_slide()

	if animation_locked:
		return

	real_velocity = get_real_velocity()

	if real_velocity.length() > 1:
		last_direction = direction
		_play_animation(direction)
	else:
		_play_animation(Vector2.ZERO)


	# --- Pushable rock detection
	if Input.is_action_pressed("arrow_left"):
		var space_state = get_world_2d().direct_space_state
		var cast_from = global_position
		var cast_to = global_position + Vector2.LEFT * 10
		var query = PhysicsRayQueryParameters2D.create(cast_from, cast_to)
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result and result.collider is CharacterBody2D and "rock" in result.collider.name:
			# Trigger the pushing animation
			animated_sprite_2d.play("push_left")
			result.collider.push_left()
			
func _on_map_toggled(is_open: bool) -> void:
	force_cannot_move = is_open
	
func _apply_wind_effects() -> void:
	if is_in_wind and wind_source:
		if not _is_wind_blocked():
			velocity += wind_force

func _is_wind_blocked() -> bool:
	if wind_force == Vector2.ZERO:
		return false
	var from := global_position
	var to := from - wind_force.normalized() * wind_check_length
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	query.collision_mask = wind_block_mask
	var result = get_world_2d().direct_space_state.intersect_ray(query)
	if result and result.collider and "rock" in result.collider.name.to_lower():
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	# NEW: Track input priority for direction changes
	if event.is_action_pressed("arrow_left"):
		_add_to_priority("arrow_left")
	elif event.is_action_pressed("arrow_right"):
		_add_to_priority("arrow_right")
	elif event.is_action_pressed("arrow_up"):
		_add_to_priority("arrow_up")
	elif event.is_action_pressed("arrow_down"):
		_add_to_priority("arrow_down")
	elif event.is_action_released("arrow_left"):
		_remove_from_priority("arrow_left")
	elif event.is_action_released("arrow_right"):
		_remove_from_priority("arrow_right")
	elif event.is_action_released("arrow_up"):
		_remove_from_priority("arrow_up")
	elif event.is_action_released("arrow_down"):
		_remove_from_priority("arrow_down")
	
	if not can_player_move():
		return

	if event.is_action_pressed("run"):
		is_running = true
	elif event.is_action_released("run"):
		is_running = false

	# Flashlight toggle
	if event.is_action_pressed("flashlight"):
		sfx_flashlight.play()
		FlashlightManager.toggle_real_flashlight()

# NEW: Helper functions for input priority
func _add_to_priority(action: String) -> void:
	# Remove if already exists (to update priority)
	if action in input_priority:
		input_priority.erase(action)
	# Add to the end (most recent)
	input_priority.append(action)

func _remove_from_priority(action: String) -> void:
	input_priority.erase(action)

func _get_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO
	
	# Use the most recently pressed direction that's still held
	for i in range(input_priority.size() - 1, -1, -1):
		var action = input_priority[i]
		if Input.is_action_pressed(action):
			match action:
				"arrow_left": direction = Vector2.LEFT
				"arrow_right": direction = Vector2.RIGHT
				"arrow_up": direction = Vector2.UP
				"arrow_down": direction = Vector2.DOWN
			break
	
	return direction

func _play_animation(direction: Vector2) -> void:
	var flashlight_on = FlashlightManager.flashlight_enabled

	if flashlight_on:
		# Flashlight animations
		if direction == Vector2.ZERO:
			match last_direction:
				Vector2.RIGHT: animated_sprite_2d.play("flashlight_idle_right")
				Vector2.LEFT: animated_sprite_2d.play("flashlight_idle_left")
				Vector2.DOWN: animated_sprite_2d.play("flashlight_idle_down")
				Vector2.UP: animated_sprite_2d.play("flashlight_idle_up")
		else:
			match direction:
				Vector2.RIGHT: animated_sprite_2d.play("flashlight_walk_right")
				Vector2.LEFT: animated_sprite_2d.play("flashlight_walk_left")
				Vector2.DOWN: animated_sprite_2d.play("flashlight_walk_down")
				Vector2.UP: animated_sprite_2d.play("flashlight_walk_up")
	else:
		# Normal animations
		if direction == Vector2.ZERO or not can_player_move():
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
	if Input.is_action_pressed("run"):
		is_running = true
	else:
		is_running = false


func show_tip(npc_name: String) -> void:
	tip_interact.visible = true
	can_interact = true
	current_npc = npc_name

func hide_tip(npc_name: String) -> void:
	tip_interact.visible = false
	can_interact = false
	current_npc = ""

func can_player_move() -> bool:
	return can_move and not force_cannot_move

# Wind interaction methods
func apply_wind(force: Vector2, source: Node2D) -> void:
	wind_force = force
	is_in_wind = true
	wind_source = source

func remove_wind(source: Node2D = null) -> void:
	wind_force = Vector2.ZERO
	is_in_wind = false
	wind_source = null

func _on_tree_exiting():
	remove_wind()
