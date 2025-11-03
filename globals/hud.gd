extends CanvasLayer
signal phone_outro_finished

@onready var v_box_container: VBoxContainer = $Control/objectives/MarginContainer/VBoxContainer
@onready var objectives_panel: Panel = $Control/objectives
const BASIS_33 = preload("res://assets/fonts/basis33.ttf")
@onready var hud_animations: AnimationPlayer = $hud_animations

@onready var photo_popup_holder: Panel = $Control/photo_popup_holder
@onready var texture_rect: TextureRect = $Control/photo_popup_holder/MarginContainer/TextureRect

const PHONE_MAIN = preload("res://scenes/game/phone_main.tscn")
const APP_CHAT = preload("res://scenes/game/app_chat.tscn")

@onready var lock_screen: Control = $Control/phone/MarginContainer/lock_screen
@onready var phone_container: MarginContainer = $Control/phone/MarginContainer

# === LOCAL FLAGS (no GameState) ===
var phone_showing: bool = false
var lock_screen_active: bool = true
var phone_main_active: bool = false
var chat_open: bool = false
var popup_showing: bool = false

func _ready() -> void:
	_restore_phone_state()


# ==================================
# === OBJECTIVES ===
# ==================================
func clear_objectives() -> void:
	for obj in v_box_container.get_children():
		obj.queue_free()

func new_objective(obj_ID: int, new_objective_text: String, color: Color = Color.BLACK) -> void:
	_create_objective_node(obj_ID, new_objective_text, color)

func done_objective(obj_ID: int, objective: String, check_color: Color = Color.DARK_BLUE, panel_done_color: Color = Color.HONEYDEW) -> void:
	for margin in v_box_container.get_children():
		if margin is MarginContainer:
			var panel = margin.get_child(0) 
			if panel is PanelContainer:
				var obj = panel.get_child(0)
				if obj.get_meta("ID") == obj_ID:
					var hex_color = "#" + check_color.to_html(false)
					obj.bbcode_enabled = true
					obj.text = "[color=%s][[b]✓[/b]] [/color]%s" % [hex_color, objective]

					if panel.has_theme_stylebox_override("panel"):
						var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
						style.bg_color = panel_done_color
						panel.add_theme_stylebox_override("panel", style)
					return


func _create_objective_node(objective_ID: int, objective_string: String, color: Color = Color.BLACK) -> void:
	var margin_container = MarginContainer.new()
	margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_container.custom_minimum_size = Vector2(300, 0)
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_top", 5)
	margin_container.add_theme_constant_override("margin_bottom", 5)

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(1, 1, 1, 1)
	panel_style.set_corner_radius_all(15)
	panel_style.content_margin_left = 15 
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", panel_style)

	var objective_label = RichTextLabel.new()
	objective_label.bbcode_enabled = true
	objective_label.fit_content = true
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	objective_label.add_theme_font_override("normal_font", BASIS_33)
	objective_label.add_theme_font_size_override("normal_font_size", 24)
	objective_label.add_theme_color_override("default_color", color)
	objective_label.add_theme_color_override("font_strikethrough_color", Color.RED)
	objective_label.add_theme_constant_override("font_strikethrough_width", 3)
	objective_label.text = "[ ] " + str(objective_string)
	objective_label.set_meta("ID", objective_ID)

	panel.add_child(objective_label)
	margin_container.add_child(panel)
	v_box_container.add_child(margin_container)

func show_objectives() -> void:
	objectives_panel.visible = true
	objective_intro_anim()

func hide_objectives() -> void:
	objectives_panel.visible = false
	objective_outro_anim()

func update_objective_text(obj_ID: int, new_text: String) -> void:
	for margin in v_box_container.get_children():
		if margin is MarginContainer:
			var panel = margin.get_child(0)
			if panel is PanelContainer:
				var obj = panel.get_child(0)
				if obj.get_meta("ID") == obj_ID:
					obj.text = "[ ] " + new_text
					return



func objective_intro_anim() -> void:
	hud_animations.play("objective_in")

func objective_outro_anim() -> void:
	hud_animations.play("objective_out")
	SignalBus.phone_out.emit()


# ==================================
# === PHONE HANDLING (local only) ===
# ==================================
func phone_intro(time_string: String = "12:00", meridiem_string: String = "AM") -> void:
	if has_node("Control/phone"):
		var phone_node = get_node("Control/phone")
		if not phone_node.visible:
			phone_node.visible = true

	# Update lock screen labels
	var time_label = phone_container.get_node("lock_screen/Panel/time") as Label
	if time_label:
		time_label.text = time_string

	var meridiem_label = phone_container.get_node("lock_screen/Panel/meridiem") as Label
	if meridiem_label:
		meridiem_label.text = meridiem_string

	phone_showing = true
	hud_animations.play("phone_in")
	SignalBus.phone_in.emit()


func phone_outro() -> void:
	phone_showing = false
	hud_animations.play("phone_out")
	SignalBus.phone_out.emit()

func toggle_phone() -> void:
	if phone_showing:
		phone_outro()
	else:
		phone_intro()
	
# ==================================
# === POPUP HANDLING ===
# ==================================
func _toggle_popup() -> void:
	if popup_showing:
		hud_animations.play("popup_out")
		popup_showing = false
	else:
		hud_animations.play("popup_in")
		popup_showing = true

func show_popup() -> void:
	if not popup_showing:
		hud_animations.play("popup_in")
		popup_showing = true

func hide_popup() -> void:
	if popup_showing:
		hud_animations.play("popup_out")
		popup_showing = false

func add_popup_image(image_path: String) -> void:
	var image = load(image_path) as Texture2D
	texture_rect.texture = image

func clear_popup_image() -> void:
	texture_rect.texture = null


# ==================================
# === SHOW PHONE W/ UNKNOWN SENDER ===
# ==================================
func show_phone_with_unknown_sender() -> void:
	# --- Show phone if hidden ---
	if not phone_showing:
		phone_intro()  # plays "phone_in"
		phone_showing = true

	# --- Ensure APP_CHAT exists but keep it hidden initially ---
	var app_chat: Node
	if not phone_container.has_node("app_chat"):
		app_chat = APP_CHAT.instantiate()
		app_chat.name = "app_chat"
		app_chat.visible = false
		phone_container.add_child(app_chat)
		chat_open = true
	else:
		app_chat = phone_container.get_node("app_chat")
		app_chat.visible = false
		chat_open = true

	app_chat.visible = true

	# --- Trigger unknown sender chat safely ---
	if "unlock_unknown_sender" in app_chat:
		app_chat.unlock_unknown_sender()
	if "_on_unknown_sender_pressed" in app_chat:
		app_chat._on_unknown_sender_pressed()



# ===========================
# ===  RESET PHONE STATE  ===
# ===========================
func reset_phone_state(time_string: String = "12:00", meridiem_string: String = "AM") -> void:
	if has_node("Control/phone"):
		var phone_node = get_node("Control/phone")
		if not phone_node.visible:
			phone_node.visible = true
			
	for child in phone_container.get_children():
		child.queue_free()

	await get_tree().process_frame 

	lock_screen_active = true
	phone_main_active = false
	chat_open = false
	phone_showing = false

	var lock_screen_scene = preload("res://scenes/game/lock_screen.tscn").instantiate()
	lock_screen_scene.name = "lock_screen"
	phone_container.add_child(lock_screen_scene)
	lock_screen_scene.visible = true

	phone_intro(time_string, meridiem_string)


# ==================================
# === RESTORE PHONE STATE (local) ===
# ==================================
func _restore_phone_state() -> void:
	if not phone_showing:
		return

	if lock_screen_active:
		if not phone_container.has_node("lock_screen"):
			var lock_screen_scene = preload("res://scenes/game/lock_screen.tscn").instantiate()
			phone_container.add_child(lock_screen_scene)

	if phone_main_active:
		if not phone_container.has_node("phone_main"):
			var phone_main = PHONE_MAIN.instantiate()
			phone_container.add_child(phone_main)

	if chat_open:
		if not phone_container.has_node("app_chat"):
			var app_chat = APP_CHAT.instantiate()
			phone_container.add_child(app_chat)
			app_chat.visible = true






func reset_phone_dont_show() -> void:
	for child in phone_container.get_children():
		child.queue_free()

	lock_screen_active = true
	phone_main_active = false
	chat_open = false
	phone_showing = false

	await get_tree().create_timer(0.2).timeout

	var lock_screen_scene = preload("res://scenes/game/lock_screen.tscn").instantiate()
	phone_container.add_child(lock_screen_scene)
	lock_screen_scene.visible = true
