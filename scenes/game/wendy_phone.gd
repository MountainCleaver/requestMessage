extends Control

@onready var chat: Button = $screen/MarginContainer/GridContainer/CHAT
@onready var call: Button = $screen/TextureRect/MarginContainer2/GridContainer/CALL
@onready var sched: Button = $screen/MarginContainer/GridContainer/SCHED
@onready var gallery: Button = $screen/MarginContainer/GridContainer/GALLERY

func _ready() -> void:
	call.pressed.connect(_on_call_pressed)

func _on_call_pressed() -> void:
	print("Opening Wendy’s Call App...")
	var call_app = preload("res://scenes/game/app_call_wendy.tscn").instantiate()
	get_parent().add_child(call_app)
	call_app.previous_scene = self   # <--- important line
	self.visible = false
