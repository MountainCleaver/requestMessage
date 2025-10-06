extends Control

@onready var danilo_btn: Button = $screen/Panel/MarginContainer5/Panel/DANILO
@onready var mira_btn: Button = $screen/MarginContainer6/Panel2/MIRA
@onready var group_chat_btn: Button = $screen/MarginContainer7/Panel3/GROUP_CALL
@onready var exit: Button = $screen/Panel/EXIT

var previous_scene: Control = null

var danilo_scene: Control = null
var mira_scene: Control = null
var group_chat_scene: Control = null
var unknown_sender_scene: Control = null
var unknown_unlocked: bool = false

func _ready() -> void:
	if not danilo_btn.pressed.is_connected(_on_danilo_pressed):
		danilo_btn.pressed.connect(_on_danilo_pressed)
	if not mira_btn.pressed.is_connected(_on_mira_pressed):
		mira_btn.pressed.connect(_on_mira_pressed)
	if not group_chat_btn.pressed.is_connected(_on_group_chat_pressed):
		group_chat_btn.pressed.connect(_on_group_chat_pressed)


func _on_danilo_pressed() -> void:
	SignalBus.chat_opened.emit("danilo")
	if danilo_scene == null:
		danilo_scene = preload("res://scenes/game/app_chat_convo.tscn").instantiate()
		danilo_scene.previous_scene = self
		get_parent().add_child(danilo_scene)
	danilo_scene.set_current_chat("danilo")
	visible = false
	danilo_scene.visible = true

func _on_mira_pressed() -> void:
	SignalBus.chat_opened.emit("mira")
	if mira_scene == null:
		mira_scene = preload("res://scenes/game/app_chat_convo.tscn").instantiate()
		mira_scene.previous_scene = self
		get_parent().add_child(mira_scene)
	mira_scene.set_current_chat("mira")
	visible = false
	mira_scene.visible = true

func _on_group_chat_pressed() -> void:
	SignalBus.chat_opened.emit("group_chat")
	if group_chat_scene == null:
		group_chat_scene = preload("res://scenes/game/app_chat_convo.tscn").instantiate()
		group_chat_scene.previous_scene = self
		get_parent().add_child(group_chat_scene)
	group_chat_scene.set_current_chat("group_chat")
	visible = false
	group_chat_scene.visible = true
