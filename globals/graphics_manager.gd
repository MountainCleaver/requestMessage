extends Node

# Quality Levels
enum Quality { LOW, MEDIUM, HIGH }
var current_quality: Quality = Quality.HIGH

# HARCODED HAHAHAHAHA
var scenes_to_optimize := [
	"res://scenes/game/act_1/scene_1/danilo_room.tscn",
	"res://scenes/game/act_1/scene_1/act_1_scene_1.tscn",
	"res://scenes/game/act_1/scene_2/act_1_scene_2.tscn",
	"res://scenes/game/act_1/scene_2/danilo_neighborhood.tscn",
	"res://scenes/game/act_1/scene_2/rizal_park.tscn"
	
]

func _ready():
	detect_quality()
	print("[GraphicsManager] Detected device quality:", current_quality)

# Detect device capability (example: screen width or RAM)
func detect_quality():
	var screen_size = DisplayServer.window_get_size()
	print("[GraphicsManager] Screen size:", screen_size)
	if screen_size.x <= 1280:
		current_quality = Quality.LOW
	elif screen_size.x <= 1920:
		current_quality = Quality.MEDIUM
	else:
		current_quality = Quality.HIGH

# Call this whenever you load a scene
func optimize_scene(scene_root: Node):
	print("[GraphicsManager] Optimizing scene:", scene_root.name)
	_scale_tilemaps(scene_root)

# Recursively scale all TileMaps in the scene
func _scale_tilemaps(node: Node):
	if node is TileMap:
		print("[GraphicsManager] Scaling TileMap:", node.name)
		_apply_quality(node)
	for child in node.get_children():
		_scale_tilemaps(child)

# Apply scale/cell size based on quality
func _apply_quality(tilemap: TileMap):
	match current_quality:
		Quality.LOW:
			tilemap.scale = Vector2(0.5, 0.5)
			tilemap.cell_size *= 0.5
			tilemap.y_sort_enabled = false 
			tilemap.light_mask = 0
			print("[GraphicsManager] LOW quality applied:", tilemap.name)
		Quality.MEDIUM:
			tilemap.scale = Vector2(0.75, 0.75)
			tilemap.cell_size *= 0.75
			tilemap.y_sort_enabled = false
			print("[GraphicsManager] MEDIUM quality applied:", tilemap.name)
		Quality.HIGH:
			tilemap.scale = Vector2(1, 1)
			tilemap.cell_size *= 1
			tilemap.y_sort_enabled = true
			print("[GraphicsManager] HIGH quality applied:", tilemap.name)
