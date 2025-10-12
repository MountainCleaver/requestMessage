extends Control

@onready var wendy_btn: Button = $screen/MarginContainer/Panel/WENDY
@onready var mira_btn: Button = $screen/MarginContainer2/Panel2/MIRA
@onready var group_chat_btn: Button = $screen/MarginContainer3/Panel3/GROUP_CHAT
@onready var unknown_sender_btn: Button = $screen/MarginContainer4/Panel4/UNKNOWN_SENDER
@onready var unknown_sender_container: MarginContainer = $screen/MarginContainer4
@onready var unknown_sender_label: Label = $screen/MarginContainer4/Panel4/UNKNOWN_SENDER/Label
@onready var exit: Button = $screen/Panel/EXIT


var previous_scene: Control = null

var wendy_scene: Control = null
var mira_scene: Control = null
var group_chat_scene: Control = null
var unknown_sender_scene: Control = null
var unknown_unlocked: bool = false

func _ready() -> void:
	if not wendy_btn.pressed.is_connected(_on_wendy_pressed):
		wendy_btn.pressed.connect(_on_wendy_pressed)
	if not mira_btn.pressed.is_connected(_on_mira_pressed):
		mira_btn.pressed.connect(_on_mira_pressed)
	if not group_chat_btn.pressed.is_connected(_on_group_chat_pressed):
		group_chat_btn.pressed.connect(_on_group_chat_pressed)
	if not unknown_sender_btn.pressed.is_connected(_on_unknown_sender_pressed):
		unknown_sender_btn.pressed.connect(_on_unknown_sender_pressed)
	if not exit.pressed.is_connected(_on_exit_pressed):
		exit.pressed.connect(_on_exit_pressed)

	unknown_sender_container.visible = SignalBus.unknown_sender_unlocked
	unknown_sender_label.visible = SignalBus.unknown_sender_label_visible

func unlock_unknown_sender():
	SignalBus.unknown_sender_unlocked = true
	if unknown_sender_container:
		unknown_sender_container.visible = true

func _on_wendy_pressed() -> void:
	SignalBus.chat_opened.emit("wendy")
	if wendy_scene == null:
		wendy_scene = preload("res://scenes/game/app_chat_convo.tscn").instantiate()
		wendy_scene.previous_scene = self
		get_parent().add_child(wendy_scene)
	wendy_scene.set_current_chat("wendy")
	visible = false
	wendy_scene.visible = true

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

func _on_unknown_sender_pressed() -> void:
	SignalBus.chat_opened.emit("unknown_sender")
	if unknown_sender_scene == null:
		unknown_sender_scene = preload("res://scenes/game/app_chat_convo.tscn").instantiate()
		unknown_sender_scene.previous_scene = self
		get_parent().add_child(unknown_sender_scene)
	unknown_sender_scene.set_current_chat("unknown_sender")
	visible = false
	unknown_sender_scene.visible = true
	
func _on_exit_pressed() -> void:
	if previous_scene:
		previous_scene.visible = true
	visible = false
	queue_free()
