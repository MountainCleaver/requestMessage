extends Node2D 

# ===================
# PRELOADS
# ===================
const A_5S_1 = preload("res://dialogues/act_5/scene_1/a5s1.dialogue")
const DARK_FOREST = preload("res://scenes/game/act_5/scene_1/dark_forest.tscn")
const CHAPEL_EXTERIOR = preload("res://scenes/game/act_5/scene_1/chapel_exterior.tscn")
const CHAPEL_INTERIOR = preload("res://scenes/game/act_5/scene_1/chapel_interior.tscn")
const NARRATION_PANEL = preload("res://helpers/narration_panel.tscn")

# ===================
# NODES
# ===================
@onready var locations: Node2D = $locations
var player_danilo: CharacterBody2D
var tip_interact: Sprite2D
var current_location: Node

# Areas
var dark_forest_entrance_area: Area2D
var door_area: Area2D
var before_door_area: Area2D
var lighter_area: Area2D
var lighter_node: Node2D
var big_candle_area: Area2D
var exit_area: Area2D
var exit_chapel_exterior_area: Area2D
var signage: Area2D


# ===================
# OBJECTIVES
# ===================
var scene_objectives = [
	{"ID": 1, "text": "Return to the old chapel"},
	{"ID": 2, "text": "Find the hidden path"}
]
