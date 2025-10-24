extends Node2D

var player_danilo : CharacterBody2D

@onready var npc_gino: CharacterBody2D = $"danilo_hometown/y-sorted-objects/npcs/npc_gino"
@onready var npc_jonathan: CharacterBody2D = $"danilo_hometown/y-sorted-objects/npcs/npc_jonathan"
@onready var npc_theresa_scene_4: CharacterBody2D = $"danilo_hometown/y-sorted-objects/npcs/npc_theresa_scene_4"
@onready var npc_vanessa_scene_4: CharacterBody2D = $"danilo_hometown/y-sorted-objects/npcs/npc_vanessa_scene_4"

@onready var theresa_animated_sprite_2d: AnimatedSprite2D = $"danilo_hometown/y-sorted-objects/npcs/npc_theresa_scene_4/AnimatedSprite2D"
@onready var vanesa_animated_sprite_2d: AnimatedSprite2D = $"danilo_hometown/y-sorted-objects/npcs/npc_vanessa_scene_4/AnimatedSprite2D"
@onready var jonathan_animated_sprite_2d: AnimatedSprite2D = $"danilo_hometown/y-sorted-objects/npcs/npc_jonathan/AnimatedSprite2D"


@onready var jonathan_spawn: Marker2D = $"danilo_hometown/y-sorted-objects/spawn_points/jonathan_spawn"
@onready var jonathan_spawn_talk: Marker2D = $"danilo_hometown/y-sorted-objects/spawn_points/jonathan_spawn_talk"
@onready var theresa_spawn: Marker2D = $"danilo_hometown/y-sorted-objects/spawn_points/theresa_spawn"
@onready var vanessa_spawn: Marker2D = $"danilo_hometown/y-sorted-objects/spawn_points/vanessa_spawn"

@onready var with_jonathan: Marker2D = $"danilo_hometown/y-sorted-objects/spawn_points/with_jonathan"
@onready var with_theresa_spawn: Marker2D = $"danilo_hometown/y-sorted-objects/spawn_points/with_theresa_spawn"


@onready var gino: Area2D = $"danilo_hometown/y-sorted-objects/areas/gino"
@onready var vanessa: Area2D = $"danilo_hometown/y-sorted-objects/areas/vanessa"
@onready var jonathan: Area2D = $"danilo_hometown/y-sorted-objects/areas/jonathan"
@onready var theresa: Area2D = $"danilo_hometown/y-sorted-objects/areas/theresa"
@onready var jonathan_appear: Area2D = $"danilo_hometown/y-sorted-objects/areas/jonathan_appear"
@onready var jonathan_stop: Area2D = $"danilo_hometown/y-sorted-objects/areas/jonathan_stop"

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var directional_light_2d: DirectionalLight2D = $DirectionalLight2D

var theresa_done : bool = false
var first_time_here : bool = true

var count_neighbors_asked : int = 0;

func _ready() -> void:
	FlashlightManager.set_current_scene("act_3", "scene_4")
	FlashlightManager.disable_flashlights()
	get_tree().node_added.connect(_on_node_added)
	
	SignalBus.start_theresa.connect(_on_start_theresa)
	SignalBus.start_vanesa.connect(_on_start_vanesa)
	SignalBus.knocked_jonathan.connect(_on_knocked_jonathan)
	SignalBus.jonathan_done.connect(_on_jonathan_done)
	
	SignalBus.asked_a_neighbor.connect(_get_dimmer)
	
	SignalBus.remove_npc.connect(_remove_npc)
	
	vanesa_animated_sprite_2d.play("idle_up")
	#_get_dimmer()

var light_strenths : Array[float] = [
	0.4,
	0.3,
	0.2,
	0.1
]

var modulate_values : Array[Color] = [
	Color("#ffffff"),
	Color("#d29ca8"),
	Color("#944d90"),
	Color("#283097")
]

func _get_dimmer()->void:
	directional_light_2d.energy = light_strenths[count_neighbors_asked]
	canvas_modulate.color = modulate_values[count_neighbors_asked]
	count_neighbors_asked += 1

func _on_node_added(node: Node) -> void:
	if node.name == "player_danilo":
		player_danilo = node
		get_tree().disconnect("node_added", Callable(self, "_on_node_added"))

func _on_knocked_jonathan()->void:
	jonathan_appear.monitoring = true

func _on_start_vanesa() -> void:
	vanesa_animated_sprite_2d.play("idle_down")

func _on_start_theresa () -> void:
	
	if not theresa_done:
		TransitionFade.transition()
		await SignalBus.on_transition_finished
		player_danilo.force_cannot_move = true
		
		theresa.queue_free()
		npc_theresa_scene_4.global_position = theresa_spawn.global_position
		theresa_animated_sprite_2d.play("idle_right")
		
		player_danilo.global_position = with_theresa_spawn.global_position
		player_danilo.last_direction = Vector2.LEFT
		theresa_done = true

func _jonathan_appear_and_walk()->void:
	
	npc_jonathan.global_position = jonathan_spawn.global_position
	npc_jonathan.direction = Vector2.LEFT



# SignalBus.remove_npc.emit("npc_theresa_scene_4")
func _remove_npc(npc: String) -> void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	var npcs_container = "danilo_hometown/y-sorted-objects/npcs/"
	var node = get_node_or_null(npcs_container+npc)
	
	if node:
		node.queue_free()
	else:
		push_warning("NPC '%s' not found in container '%s'" % [npc, npcs_container])

	node.queue_free()
	


func _on_gino_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("door_gino")

func _on_gino_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("")

func _on_vanessa_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("area_vanessa")

func _on_vanessa_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("")

func _on_jonathan_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("door_jonathan")

func _on_jonathan_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("")

func _on_theresa_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("door_theresa")

func _on_theresa_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("")

func _on_karatula_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("karatula")

func _on_karatula_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("")

func _on_jonathan_appear_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		player_danilo.force_cannot_move = true
		jonathan_stop.monitoring = true
		_jonathan_appear_and_walk()

func _on_jonathan_stop_body_entered(body: Node2D) -> void:
	print("entered")
	if body.name == "npc_jonathan":
		print("entered by jonathan")
		npc_jonathan.direction = Vector2.ZERO
		jonathan_animated_sprite_2d.play("idle_left")
		await get_tree().create_timer(1.0).timeout
		_jonathan_and_danilo_talking()

func _jonathan_and_danilo_talking()->void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	
	npc_jonathan.global_position = jonathan_spawn_talk.global_position
	jonathan_animated_sprite_2d.play("idle_right")
	
	player_danilo.global_position = with_jonathan.global_position
	player_danilo.last_direction = Vector2.LEFT
	
	jonathan_appear.queue_free()
	jonathan_stop.queue_free()
	jonathan.queue_free()
	
	SignalBus.start_jonathan.emit()

func _on_jonathan_done(npc: String)->void:
	_remove_npc(npc)


func _on_home_door_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		if first_time_here:
			first_time_here = false
			return
		
		SignalBus.in_npc.emit("home_door")

func _on_home_door_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("")
