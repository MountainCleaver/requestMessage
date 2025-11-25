extends Node2D

var player_danilo : Node2D 
var camera_2d : Camera2D

@onready var door_area: Area2D = $"danilo_hometown_house/y-sorted/areas/door_area"
@onready var picture_area: Area2D = $danilo_hometown_house/map/picture_frame/picture_area

@onready var picture_frame: Sprite2D = $danilo_hometown_house/map/picture_frame
@onready var blackkk: TileMapLayer = $danilo_hometown_house/map/blackkk
@onready var walls_and_ground: TileMapLayer = $danilo_hometown_house/map/walls_and_ground
@onready var background_elements: TileMapLayer = $danilo_hometown_house/map/background_elements
@onready var window_1: Sprite2D = $danilo_hometown_house/map/window_1
@onready var window_2: Sprite2D = $danilo_hometown_house/map/window_2
@onready var window_3: Sprite2D = $danilo_hometown_house/map/window_3
@onready var decorations: TileMapLayer = $"danilo_hometown_house/y-sorted/decorations"
@onready var spawn_points: Node2D = $"danilo_hometown_house/y-sorted/spawn_points"
@onready var areas: Node2D = $"danilo_hometown_house/y-sorted/areas"

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var night: Node2D = $night

var asked_neighbors : bool = true


func _ready() -> void:
	FlashlightManager.set_current_scene("act_3", "scene_4")
	FlashlightManager.disable_flashlights()
	SignalBus.fade_to_blackness.connect(_fade_to_black)
	get_tree().node_added.connect(_on_node_added)
	_set_image()

func _fade_to_black() -> void:
	animation_player.play("fade_to_blackness")
	await animation_player.animation_finished 
	_show_texts_sequence() 

func _show_texts_sequence() -> void:
	var texts_container := $texts
	var delay := 0.0

	for child in texts_container.get_children():
		if child is RichTextLabel:
			child.modulate.a = 0.0 
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(child, "modulate:a", 1.0, 1.0).set_delay(delay)
			delay += 2.0

func _set_image()->void:
	if not SignalBus.asked_neighbors_done: 
		picture_frame.region_rect = Rect2(32.0, 0.0, 32.0, 16.0)
		picture_area.monitoring = false
		night.hide()
	else:
		picture_frame.region_rect = Rect2(0.0, 0.0, 32.0, 16.0)
		picture_area.monitoring = true
		night.show()

func _on_node_added(node: Node) -> void:
	if node.name == "player_danilo":
		player_danilo = node
	elif node is Camera2D:
		camera_2d = node

	if player_danilo != null and camera_2d != null:
		get_tree().disconnect("node_added", Callable(self, "_on_node_added"))
 
func _tween_camera_to_center() -> void:
	if camera_2d == null or player_danilo == null:
		return
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(camera_2d, "global_position", player_danilo.global_position, 1.0)


func _on_door_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		if SignalBus.asked_neighbors_done:
			return
		SignalBus.in_npc.emit("door_inside")


func _on_door_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("")

func _on_picture_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("picture_frame")

func _on_picture_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("")

func _remove_elements_from_tree()->void:
	door_area.queue_free()
	picture_area.queue_free()
	picture_frame.queue_free()
	blackkk.queue_free()
	walls_and_ground.queue_free()
	background_elements.queue_free()
	window_1.queue_free()
	window_2.queue_free()
	window_3.queue_free()
	decorations.queue_free()
	spawn_points.queue_free()
	areas.queue_free()
	if not player_danilo.force_cannot_move:
		player_danilo.force_cannot_move = true

func _danilo_face()->void:
	player_danilo.last_direction = Vector2.DOWN
	await get_tree().create_timer(5.0).timeout
	SignalBus.last_words.emit()
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
