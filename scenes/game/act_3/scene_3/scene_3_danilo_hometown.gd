extends Node2D

@onready var animation_player: AnimationPlayer = $danilo_hometown/AnimationPlayer
@onready var jonathan_start_chase: Area2D = $"danilo_hometown/y-sorted-objects/areas/jonathan_start_chase"
@onready var npc_jonathan: CharacterBody2D = $"danilo_hometown/y-sorted-objects/npc_jonathan"

var player_danilo: Node2D
var first_time_in: bool = true
var jonathan_showed: bool = false
var bought_medicine: bool = false


func _ready() -> void:
	jonathan_start_chase.monitoring = false
	npc_jonathan.hide()
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node.name == "player_danilo":
		player_danilo = node
		get_tree().disconnect("node_added", Callable(self, "_on_node_added"))


func _process(_delta: float) -> void:
	if not player_danilo:
		return

	# Only show Jonathan logic if medicine is bought
	if SignalBus.bought_meds:
		if npc_jonathan.visible:
			npc_jonathan.position.y = player_danilo.position.y + 150
	else:
		npc_jonathan.hide()


# --- AREA HANDLERS ---

func _on_tricycle_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("tricycle_hometown")

func _on_tricycle_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("tricycle_hometown")


func _on_karatula_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("karatula")

func _on_karatula_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("karatula")


func _on_house_door_outside_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return

	if first_time_in:
		first_time_in = false
		return

	SignalBus.in_npc.emit("door_outside")

func _on_house_door_outside_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("door_outside")

func _on_jonathan_start_chase_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo" and bought_medicine:
		animation_player.play("jonathan_pop_out")
		npc_jonathan.visible = true

func _on_jonathan_start_chase_body_exited(body: Node2D) -> void:
	jonathan_showed = false
