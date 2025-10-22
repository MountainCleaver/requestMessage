extends Node2D

@onready var player_mateo: CharacterBody2D = $player_mateo
@onready var danilo: CharacterBody2D = $npc_danilo
@onready var animated_sprite_2d: AnimatedSprite2D = $npc_danilo/AnimatedSprite2D
@onready var wendy: CharacterBody2D = $wendy

var mateo_positions: Array[Dictionary] = []
var danilo_follow_distance: int = 15
var wendy_follow_distance: int = 30
var player_idle: bool = false  # separate idle tracker

const DIR_EPSILON: float = 0.05

func _ready() -> void:
	$npc_danilo/CollisionShape2D.disabled = true
	
	# Pre-fill positions with initial data to avoid index errors
	for i in range(wendy_follow_distance):
		mateo_positions.append({"position": player_mateo.global_position, "direction": Vector2.DOWN})

func _process(delta: float) -> void:
	# 🚫 Skip position updates if Mateo cannot move
	if player_mateo.force_cannot_move:
		player_idle = true
	else:
		# Record Mateo's movement only if actually moving
		if player_mateo.real_velocity.length() > 0:
			player_idle = false
			var position_and_direction: Dictionary = {
				"direction": player_mateo.velocity.normalized(),
				"position": player_mateo.global_position
			}
			mateo_positions.push_front(position_and_direction)
			
			# Keep buffer trimmed to max follow distance
			if mateo_positions.size() > wendy_follow_distance:
				mateo_positions.pop_back()
		else:
			player_idle = true

	# --- Danilo follows ---
	if mateo_positions.size() >= danilo_follow_distance:
		var danilo_index: int = danilo_follow_distance - 1
		var follow_data: Dictionary = mateo_positions[danilo_index]
		danilo.global_position = follow_data["position"]

		var dir_d: Vector2 = follow_data["direction"]
		danilo.direction = dir_d if (not player_idle and dir_d.length() >= DIR_EPSILON) else Vector2.ZERO

	# --- Wendy follows ---
	if mateo_positions.size() >= wendy_follow_distance:
		var wendy_index: int = wendy_follow_distance - 1
		var wen_follow_data: Dictionary = mateo_positions[wendy_index]
		wendy.global_position = wen_follow_data["position"]

		var dir_w: Vector2 = wen_follow_data["direction"]
		wendy.direction = dir_w if (not player_idle and dir_w.length() >= DIR_EPSILON) else Vector2.ZERO
