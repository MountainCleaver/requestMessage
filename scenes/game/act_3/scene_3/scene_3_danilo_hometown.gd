extends Node2D

@onready var npc_jonathan: CharacterBody2D = $"danilo_hometown/y-sorted-objects/npc_jonathan"
@onready var jonathan_chase_1: Area2D = $"danilo_hometown/y-sorted-objects/areas/jonathan_chase_1"
@onready var jonathan_chase_2: Area2D = $"danilo_hometown/y-sorted-objects/areas/jonathan_chase_2"
@onready var jonathan_chase_3: Area2D = $"danilo_hometown/y-sorted-objects/areas/jonathan_chase_3"


@onready var spawn_1: Marker2D = $"danilo_hometown/y-sorted-objects/jonathan_spawn/spawn_1"
@onready var spawn_2: Marker2D = $"danilo_hometown/y-sorted-objects/jonathan_spawn/spawn_2"
@onready var spawn_3: Marker2D = $"danilo_hometown/y-sorted-objects/jonathan_spawn/spawn_3"

var player_danilo: Node2D
var first_time_in: bool = true
var jonathan_showed: bool = false
var bought_medicine: bool = false

var inside_chase_zone: bool = false



func _ready() -> void:
	FlashlightManager.set_current_scene("act_3", "scene_3")
	FlashlightManager.disable_flashlights()
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.name == "player_danilo":
		player_danilo = node
		get_tree().disconnect("node_added", Callable(self, "_on_node_added"))



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
	
	if not SignalBus.bought_meds:
		return
	elif SignalBus.bought_meds:
		SignalBus.in_npc.emit("door_outside")

	if first_time_in:
		first_time_in = false
		return

	SignalBus.in_npc.emit("door_outside")

func _on_house_door_outside_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("door_outside")


func _on_jonathan_chase_1_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		if SignalBus.bought_meds:
			SignalBus.area_one_entered.emit()
			npc_jonathan.show()
			npc_jonathan.position = spawn_1.global_position



func _on_jonathan_chase_1_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		if SignalBus.bought_meds:
			npc_jonathan.hide()
			jonathan_chase_1.queue_free()


func _on_jonathan_chase_2_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		if SignalBus.bought_meds:
			npc_jonathan.show()
			npc_jonathan.position = spawn_2.global_position


func _on_jonathan_chase_2_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		if SignalBus.bought_meds:
			npc_jonathan.hide()
			jonathan_chase_2.queue_free()


func _on_jonathan_chase_3_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		if SignalBus.bought_meds:
			npc_jonathan.show()
			npc_jonathan.position = spawn_3.global_position



func _on_jonathan_chase_3_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		if SignalBus.bought_meds:
			npc_jonathan.hide()
			jonathan_chase_3.queue_free()


func _on_check_outside_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
		
 