extends Node2D

@onready var player_danilo: CharacterBody2D = $player_danilo
@onready var wendy: CharacterBody2D = $wendy
@onready var animated_sprite_2d: AnimatedSprite2D = $wendy/AnimatedSprite2D
@onready var area_2d: Area2D = $wendy/Area2D

var danilo_positions: Array[Dictionary] = [
	{"position": Vector2(-20.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-19.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-18.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-17.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-16.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-15.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-14.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-13.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-12.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-11.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-10.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-9.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-8.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-7.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-6.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-5.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-4.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-3.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-2.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(-1.0, 0.0), "direction": Vector2.LEFT},
	{"position": Vector2(0.0, 0.0), "direction": Vector2.LEFT}
	]
var wendy_follow_distance: int = 20
var player_idle: bool = false  # separate idle tracker

func _ready() -> void:
	$wendy/CollisionShape2D.disabled = true;
	$wendy/Area2D.monitoring = false;
	
func _process(delta: float) -> void:
	# Check Danilo's state

	if player_danilo.real_velocity.length() > 0:
		player_idle = false
		var danilo_position_and_direction: Dictionary = {
			"direction": player_danilo.velocity.normalized(),
			"position": player_danilo.global_position
		}
		danilo_positions.push_front(danilo_position_and_direction)
		
		# Keep fixed buffer
		if danilo_positions.size() > wendy_follow_distance:
			danilo_positions.pop_back()
	else:
		player_idle = true
	
	# Only update Wendy if enough positions recorded
	if danilo_positions.size() >= wendy_follow_distance:
		var follow_data = danilo_positions[wendy_follow_distance - 1]
		wendy.global_position = follow_data["position"]
		
		if player_idle:
			# Force idle regardless of history
			wendy.direction = Vector2.ZERO
		else:
			wendy.direction = follow_data["direction"]
