extends CanvasLayer

@onready var v_box_container: VBoxContainer = $Control/objectives/MarginContainer/VBoxContainer
@onready var objectives_panel: Panel = $Control/objectives;
const BASIS_33 = preload("res://assets/fonts/basis33.ttf");
@onready var hud_animations: AnimationPlayer = $hud_animations

@onready var photo_popup_holder: Panel = $Control/photo_popup_holder
@onready var texture_rect: TextureRect = $Control/photo_popup_holder/MarginContainer/TextureRect

const PHONE_MAIN = preload("res://scenes/game/phone_main.tscn")
const APP_CHAT = preload("res://scenes/game/app_chat.tscn")

var popup_showing = false;

@onready var lock_screen: Control = $Control/phone/MarginContainer/lock_screen
@onready var phone_container: MarginContainer = $Control/phone/MarginContainer

# FLAGS
var phone_showing: bool = false
var lock_screen_active: bool = true
var phone_main_active: bool = false
var chat_open: bool = false

func _ready() -> void:
	# Restore phone state from GameState when HUD loads
	_restore_phone_state()
	
func clear_objectives() -> void:
	for obj in v_box_container.get_children():
		obj.queue_free();

func new_objective(obj_ID: int, new_objective_text: String, color: Color = Color.BLACK) -> void:
	_create_objective_node(obj_ID, new_objective_text, color)

func done_objective(obj_ID: int, objective: String) -> void: # objective = current objective, done_objective = same but with strikthough
	
	var objectives_nodes = v_box_container.get_children() as Array[RichTextLabel];
	for obj in objectives_nodes:
		if obj.get_meta("ID") == obj_ID:
			obj.text = "[✔]" + objective;

func _create_objective_node(objective_ID: int, objective_string: String, color: Color = Color.BLACK) -> void:
	var objective_node = RichTextLabel.new()
	objective_node.bbcode_enabled = true
	objective_node.fit_content = true
	objective_node.autowrap_mode = TextServer.AUTOWRAP_WORD

	objective_node.add_theme_font_override("normal_font", BASIS_33)
	objective_node.add_theme_font_size_override("normal_font_size", 24)

	# Set color based on what was passed (default black)
	objective_node.add_theme_color_override("default_color", color)
	objective_node.add_theme_color_override("font_strikethrough_color", Color.RED)
	objective_node.add_theme_constant_override("font_strikethrough_width", 3)

	objective_node.text = "[ ]" + str(objective_string)
	objective_node.set_meta("ID", objective_ID)

	v_box_container.add_child(objective_node)


func show_objectives() -> void:
	objectives_panel.visible = true;
	objective_intro_anim();

func hide_objectives() -> void:
	objectives_panel.visible = false;

func objective_intro_anim() -> void:
	hud_animations.play("objective_in");

func objective_outro_anim()-> void:
	hud_animations.play("objective_out");
	SignalBus.phone_out.emit();

func phone_intro() -> void:
	hud_animations.play("phone_in");
	SignalBus.phone_in.emit();
func phone_outro() -> void:
	hud_animations.play("phone_out");
	SignalBus.phone_out.emit();

func toggle_phone() -> void:
	if phone_showing:
		phone_outro()
		phone_showing = false
	else:
		phone_intro()
		phone_showing = true

func _toggle_popup() -> void:
	if popup_showing:
		hud_animations.play("popup_out");
		popup_showing = false;
	else:
		hud_animations.play("popup_in");
		popup_showing = true;

func add_popup_image(image_path: String) -> void:
	var image = load(image_path) as Texture2D
	texture_rect.texture = image

func clear_popup_image() -> void:
	texture_rect.texture = null;

# ==============================
# SHOW PHONE WITH UNKNOWN SENDER
# ==============================
func show_phone_with_unknown_sender() -> void:
	if not GameState.phone_showing:
		phone_intro()
		GameState.phone_showing = true

	await get_tree().create_timer(0.8).timeout

	# Hide lock screen if active
	if GameState.lock_screen_active and phone_container.has_node("lock_screen"):
		phone_container.get_node("lock_screen").visible = false
		GameState.lock_screen_active = false

	# Show or reuse phone_main
	var phone_main: Node = null
	if not GameState.phone_main_active:
		phone_main = PHONE_MAIN.instantiate()
		phone_container.add_child(phone_main)
		GameState.phone_main_active = true
	else:
		phone_main = phone_container.get_node("phone_main")

	# Open chat app
	if not GameState.chat_open:
		var app_chat = APP_CHAT.instantiate()
		phone_container.add_child(app_chat)

		# Set previous scene for exit/back logic
		app_chat.previous_scene = phone_main

		# Hide phone_main
		phone_main.visible = false
		app_chat.visible = true

		# Trigger chat logic
		app_chat.unlock_unknown_sender()
		app_chat._on_unknown_sender_pressed()

		GameState.chat_open = true


# ==============================
# RESTORE PHONE STATE (for load)
# ==============================
func _restore_phone_state() -> void:
	if not GameState.phone_showing:
		return  # phone is hidden at start

	# Show lock screen if active
	if GameState.lock_screen_active:
		if not phone_container.has_node("lock_screen"):
			var lock_screen = preload("res://scenes/game/lock_screen.tscn").instantiate()
			phone_container.add_child(lock_screen)

	# Show phone_main if active
	if GameState.phone_main_active:
		if not phone_container.has_node("phone_main"):
			var phone_main = PHONE_MAIN.instantiate()
			phone_container.add_child(phone_main)

	# Show chat app if active
	if GameState.chat_open:
		if not phone_container.has_node("app_chat"):
			var app_chat = APP_CHAT.instantiate()
			phone_container.add_child(app_chat)
			app_chat.visible = true
