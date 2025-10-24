extends Node2D

# === PLAYER & NPC REFERENCES ===
@onready var player_wendy: CharacterBody2D = $player_wendy

@onready var npc_lola_ising: CharacterBody2D = $npc_lola_ising
@onready var npc_jonathan: CharacterBody2D = $npc_jonathan
@onready var npc_vanesa: CharacterBody2D = $npc_vanesa
@onready var npc_manong_gino: CharacterBody2D = $npc_gino
@onready var npc_manang_matet: CharacterBody2D = $npc_matet
@onready var npc_aling_theresa: CharacterBody2D = $npc_aling_theresa

# NPC animation nodes
@onready var lola_ising: AnimatedSprite2D = $npc_lola_ising/AnimatedSprite2D
@onready var jonathan: AnimatedSprite2D = $npc_jonathan/AnimatedSprite2D
@onready var vanesa: AnimatedSprite2D = $npc_vanesa/AnimatedSprite2D
@onready var manong_gino: AnimatedSprite2D = $npc_gino/AnimatedSprite2D
@onready var manang_matet: AnimatedSprite2D = $npc_matet/AnimatedSprite2D
@onready var aling_theresa: AnimatedSprite2D = $npc_aling_theresa/AnimatedSprite2D

# === FOLLOW VARIABLES ===
var wendy_positions: Array[Dictionary] = []
var player_idle: bool = false
const DIR_EPSILON: float = 0.05

func _ready() -> void:
	# Optional: Disable collisions so they can overlap smoothly
	for npc in [
		$npc_lola_ising,
		$npc_jonathan,
		$npc_vanesa,
		$npc_aling_theresa,
		$npc_gino,
		$npc_matet
	]:
		var cs = npc.get_node("CollisionShape2D")
		if cs:
			cs.disabled = false


func _process(delta: float) -> void:
	# --- Record Wendy’s movement path ---
	if player_wendy.force_cannot_move:
		player_idle = true
	else:
		if player_wendy.real_velocity.length() > 0:
			player_idle = false
			var position_and_direction: Dictionary = {
				"direction": player_wendy.velocity.normalized(),
				"position": player_wendy.global_position
			}
			wendy_positions.push_front(position_and_direction)
			if wendy_positions.size() > 200:  # prevent array from growing forever
				wendy_positions.pop_back()
		else:
			player_idle = true

	# --- Make all NPCs follow Wendy in a single straight line ---
	_follow_npc(npc_lola_ising, 10)
	_follow_npc(npc_aling_theresa, 20)
	_follow_npc(npc_manang_matet, 30)
	_follow_npc(npc_jonathan, 40)
	_follow_npc(npc_vanesa, 50)
	_follow_npc(npc_manong_gino, 60)


# === SMOOTH FOLLOWING FUNCTION (OMORI-STYLE) ===
func _follow_npc(npc: CharacterBody2D, follow_index: int) -> void:
	if wendy_positions.size() <= follow_index:
		return

	var follow_data: Dictionary = wendy_positions[follow_index]
	var dir: Vector2 = follow_data["direction"]

	# --- Determine alignment (horizontal or vertical) ---
	var axis_is_horizontal: bool = abs(dir.x) > abs(dir.y)

	# --- Spacing between each character ---
	const SPACING := 20.0
	const LERP_SPEED := 0.15

	# --- Target base position ---
	var target_pos: Vector2 = follow_data["position"] - dir * SPACING

	# --- Dynamic alignment ---
	if axis_is_horizontal:
		# Keep them perfectly aligned horizontally
		target_pos.y = follow_data["position"].y
	else:
		# Keep them perfectly aligned vertically
		target_pos.x = follow_data["position"].x
		
	target_pos.y += 15.0
	target_pos.x += 10.0
	# --- Smooth snake-like movement ---
	npc.global_position = npc.global_position.lerp(target_pos, LERP_SPEED)

	# --- Copy facing direction and idle state ---
	if not player_idle and dir.length() >= DIR_EPSILON:
		npc.direction = dir
	else:
		npc.direction = Vector2.ZERO
