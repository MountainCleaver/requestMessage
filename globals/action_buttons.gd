extends Control

signal run_pressed(is_pressed: bool)
signal flashlight_pressed()
signal map_pressed()
signal interact_pressed()
signal menu_pressed()


@onready var run_button: TouchScreenButton = $RunButton
@onready var flashlight_button: TouchScreenButton = $FlashlightButton
@onready var map_button: TouchScreenButton = $MapButton
@onready var interact_button: TouchScreenButton = $InteractButton
@onready var menu_button: TouchScreenButton = $MenuButton


func _ready() -> void:
	# Run button
	run_button.pressed.connect(_on_run_pressed)
	run_button.released.connect(_on_run_released)
	
	# Flashlight
	flashlight_button.pressed.connect(_on_flashlight_pressed)
	
	# Map
	map_button.pressed.connect(_on_map_pressed)
	
	# Interact
	interact_button.pressed.connect(_on_interact_pressed)
	
	# Menu
	menu_button.pressed.connect(_on_menu_pressed)
	
# --- Handlers ---
func _on_run_pressed():
	emit_signal("run_pressed", true)

func _on_run_released():
	emit_signal("run_pressed", false)

func _on_flashlight_pressed():
	emit_signal("flashlight_pressed")

func _on_map_pressed():
	emit_signal("map_pressed")

func _on_interact_pressed():
	emit_signal("interact_pressed")
	
func _on_menu_pressed():
	emit_signal("menu_pressed")
