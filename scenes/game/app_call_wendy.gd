extends Control

@onready var danilo_btn: Button = $screen/Panel/MarginContainer5/Panel/DANILO
@onready var mira_btn: Button = $screen/MarginContainer6/Panel2/MIRA
@onready var exit: Button = $screen/Panel/EXIT

var previous_scene: Control = null
var active_call: Control = null

func _ready() -> void:
	danilo_btn.pressed.connect(_on_danilo_pressed)
	mira_btn.pressed.connect(_on_mira_pressed)
	exit.pressed.connect(_on_exit_pressed)

	if not SignalBus.is_connected("call_completed", Callable(self, "_on_call_completed")):
		SignalBus.connect("call_completed", Callable(self, "_on_call_completed"))

func _on_danilo_pressed() -> void:
	_start_call("danilo")

func _on_mira_pressed() -> void:
	_start_call("mira")

func _start_call(target: String) -> void:
	print("Calling " + target.capitalize() + "...")

	danilo_btn.disabled = true
	mira_btn.disabled = true

	active_call = preload("res://scenes/game/wendy_call.tscn").instantiate()
	active_call.set_call_target(target)
	active_call.previous_scene = self
	get_parent().add_child(active_call)
	self.visible = false

func _on_exit_pressed() -> void:
	queue_free()
	if previous_scene:
		previous_scene.visible = true

func _on_call_completed(call_name: String) -> void:
	danilo_btn.disabled = false
	mira_btn.disabled = false
	active_call = null
	if previous_scene:
		previous_scene.visible = true
