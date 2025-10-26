extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

@export var speed: float = 50.0
@export var target: CharacterBody2D

var direction: Vector2 = Vector2.ZERO
var update_timer := 0.0
const UPDATE_INTERVAL := 0.2  # seconds between path recalculations

# === Optional fine-tuning ===
const CHASE_DIRECT_DISTANCE := 1.0   # directly chase when within this range
const STOP_DISTANCE := 8.0            # stop when near target
const SMOOTH_BLEND := 0.25            # how much to bias toward target direction

var start_chase : bool = false

func _ready() -> void:
	SignalBus.start_chase.connect(_on_start_chase)
	# Make path following smoother
	navigation_agent_2d.path_desired_distance = 10.0
	navigation_agent_2d.target_desired_distance = 10.0
	navigation_agent_2d.avoidance_enabled = false  # disable steering avoidance unless needed


func _physics_process(delta: float) -> void:
	if target == null:
		return
	
	if not start_chase:
		return

	# Update navigation target less frequently to reduce jitter
	update_timer -= delta
	if update_timer <= 0.0:
		navigation_agent_2d.target_position = target.global_position
		update_timer = UPDATE_INTERVAL

	var next_pos = navigation_agent_2d.get_next_path_position()

	# If the first path point is actually farther than the target, skip it
	if global_position.distance_to(next_pos) > global_position.distance_to(target.global_position):
		direction = global_position.direction_to(target.global_position)
	else:
		direction = global_position.direction_to(next_pos)


	# === Improved direction logic ===
	if global_position.distance_to(target.global_position) < CHASE_DIRECT_DISTANCE:
		# Close enough — chase directly
		direction = global_position.direction_to(target.global_position)
	else:
		# Blend between navigation path and direct chase to reduce awkward detours
		var nav_dir = global_position.direction_to(next_pos)
		var direct_dir = global_position.direction_to(target.global_position)
		direction = nav_dir.lerp(direct_dir, SMOOTH_BLEND).normalized()

	# Stop if near target or direction is zero
	if global_position.distance_to(target.global_position) < STOP_DISTANCE or direction == Vector2.ZERO:
		velocity = Vector2.ZERO
	else:
		velocity = direction * speed

	move_and_slide()
	_update_animation()

func _on_start_chase()->void:
	start_chase = true

func _update_animation() -> void:
	if velocity.length() < 1.0:
		# Idle animation (based on last direction)
		if animated_sprite.animation.begins_with("walk_"):
			var last_direction = animated_sprite.animation.replace("walk_", "")
			animated_sprite.play("idle_" + last_direction)
	else:
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				animated_sprite.play("walk_right")
			else:
				animated_sprite.play("walk_left")
		else:
			if velocity.y > 0:
				animated_sprite.play("walk_down")
			else:
				animated_sprite.play("walk_up")


# === NPC Interaction ===
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo" or body.name == "player_wendy":
		print("Entered:", body.name)
		SignalBus.in_npc.emit("npc_manong_gino")


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo" or body.name == "player_wendy":
		print("Exited:", body.name)
		SignalBus.out_npc.emit("npc_manong_gino")
