extends Control

@onready var chat_container: VBoxContainer = $screen/ScrollContainer/VBoxContainer
@onready var scroll: ScrollContainer = $screen/ScrollContainer
@onready var panel_name: Label = $screen/Panel/Label
@onready var panel_icon: TextureRect = $screen/Panel/Icon
@onready var panel_icon_bg: Panel = $screen/Panel
@onready var background_chat: ColorRect = $screen

@onready var exit_btn: Button = $screen/Panel/EXIT
@onready var exit_btn_2: Button = $screen/Panel/EXIT_2

var previous_scene: Control
var current_chat: String = "wendy"

# === Local replacements for GameState ===
var unknown_sender_opened: bool = false

# === Existing local data ===
var unknown_sender_first_message: bool = true

var first_message_shown := {
	"wendy": true,
	"mira": true,
	"unknown_sender": true
}

var chat_loaded := {
	"wendy": false,
	"mira": false,
	"group_chat": false,
	"unknown_sender": false
}


func _ready():
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	SignalBus.chat_message_received.connect(_on_chat_message_received)
	SignalBus.type_message_clicked.connect(_on_type_message_clicked)
	SignalBus.connect("show_locked_label", Callable(self, "show_reply_locked_label"))
	
	# Restore previous behavior for unknown sender auto-open
	if unknown_sender_opened and current_chat == "unknown_sender":
		visible = true
		load_chat_history("unknown_sender")


# MESSAGE HANDLING
func _on_chat_message_received(chat_name: String, sender: String, text: String) -> void:
	if chat_name != current_chat:
		return

	var show_typing = true
	if first_message_shown.has(chat_name):
		if chat_name in ["wendy", "mira"] and first_message_shown[chat_name]:
			show_typing = false

	if show_typing and sender != "Player" and chat_name != "group_chat":
		show_typing_indicator(sender)

		var wait_time = 1.5
		if chat_name == "unknown_sender" and first_message_shown["unknown_sender"]:
			wait_time = 2.0

		await get_tree().create_timer(wait_time).timeout

	if first_message_shown.has(chat_name):
		first_message_shown[chat_name] = false

	add_message_to_chat(sender, text)
	ChatManager.add_message(chat_name, sender, text)


func add_message_to_chat(sender: String, text: String) -> void:
	if chat_container.has_node("typing_indicator"):
		chat_container.get_node("typing_indicator").queue_free()

	var chat_font = FontFile.new()
	chat_font.font_data = load("res://assets/fonts/basis33.ttf")
	var style = StyleBoxFlat.new()

	var is_image = text.begins_with("res://") and (text.ends_with(".png") or text.ends_with(".jpg") or text.ends_with(".jpeg") or text.ends_with(".webp"))

	if is_image:
		var message_container = PanelContainer.new()
		message_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		message_container.custom_minimum_size = Vector2(280, 0)

		var texture_rect = TextureRect.new()
		var texture = load(text)
		if texture:
			texture_rect.texture = texture
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			texture_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			texture_rect.custom_minimum_size = texture.get_size()
		else:
			var error_label = Label.new()
			error_label.text = "[Image failed to load]"
			error_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
			message_container.add_child(error_label)
			chat_container.add_child(message_container)
			return

		# === Create background style (renamed to image_style) ===
		var image_style = StyleBoxFlat.new()
		image_style.border_width_top = 8
		image_style.border_width_bottom = 25
		image_style.border_width_left = 35 if sender == "Player" else 8
		image_style.border_width_right = 8 if sender == "Player" else 35
		image_style.border_color = Color(1,1,1,0)
		image_style.set_corner_radius_all(15)
		image_style.set_expand_margin_all(9)

		message_container.add_theme_stylebox_override("panel", image_style)
		message_container.add_child(texture_rect)
		chat_container.add_child(message_container)

		if sender == "Player":
			style.border_width_left = 35
			style.border_width_right = 8
			if current_chat == "unknown_sender":
				style.bg_color = Color(0.15, 0, 0, 1)
			elif current_chat == "wendy":
				style.bg_color = Color(0.469, 0.345, 0.782, 1.0)
			else:
				style.bg_color = Color(0.179, 0.337, 0.229, 1.0)
		else:
			style.border_width_left = 8
			style.border_width_right = 35
			if current_chat == "unknown_sender":
				style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
			else:
				style.bg_color = Color(0.602, 0.866, 0.678, 1.0)

		style.border_width_top = 8
		style.border_width_bottom = 25
		style.border_color = Color(1,1,1,0)
		style.set_corner_radius_all(15)
		style.set_expand_margin_all(9)

		message_container.add_theme_stylebox_override("panel", style)
		message_container.add_child(texture_rect)
		chat_container.add_child(message_container)

	else:
		var label = Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size = Vector2(280, 0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		if sender == "Player":
			label.text = text
			label.add_theme_color_override("font_color", Color(1,1,1,1))
			label.add_theme_font_override("font", chat_font)
			label.add_theme_font_size_override("font_size", 25)
			style.border_width_left = 35
			style.border_width_right = 8

			if current_chat == "unknown_sender":
				style.bg_color = Color(1.0, 0.797, 0.765, 1.0)
				label.add_theme_color_override("font_color", Color(0.234, 0.0, 0.021, 1.0))
			elif current_chat == "wendy":
				style.bg_color = Color(0.469, 0.345, 0.782, 1.0)
				label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			else:
				style.bg_color = Color(0.179, 0.337, 0.229, 1.0)

		else:
			label.text = text
			label.add_theme_color_override("font_color", Color(0.006, 0.006, 0.006, 1.0))
			label.add_theme_font_override("font", chat_font)
			label.add_theme_font_size_override("font_size", 25)
			style.border_width_left = 8
			style.border_width_right = 35

			if current_chat == "unknown_sender":
				style.bg_color = Color(0.15, 0, 0, 1)
				label.add_theme_color_override("font_color", Color(1.0, 0.649, 0.594, 1.0))
			elif current_chat == "wendy":
				style.bg_color = Color(0.762, 0.717, 0.95, 1.0)
			else:
				style.bg_color = Color(0.602, 0.866, 0.678, 1.0)

		style.border_width_top = 8
		style.border_width_bottom = 25
		style.border_color = Color(1,1,1,0)
		style.set_corner_radius_all(15)
		style.set_expand_margin_all(9)
		label.add_theme_stylebox_override("normal", style)

		chat_container.add_child(label)

	await get_tree().process_frame
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value


func show_typing_indicator(sender: String) -> void:
	if chat_container.has_node("typing_indicator"):
		chat_container.get_node("typing_indicator").queue_free()

	var chat_font = FontFile.new()
	chat_font.font_data = load("res://assets/fonts/basis33.ttf")

	var typing_label = Label.new()
	typing_label.name = "typing_indicator"
	typing_label.text = sender + " is typing..."
	typing_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	typing_label.add_theme_font_override("font", chat_font)
	typing_label.add_theme_font_size_override("font_size", 25)
	typing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	typing_label.custom_minimum_size = Vector2(200, 0)

	chat_container.add_child(typing_label)

	await get_tree().process_frame
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

# CHAT CONTROL
func _on_type_message_pressed() -> void:
	if SignalBus.optional_chats_locked:
		print("Type message is disabled for optional chats.")
		return
		
	SignalBus.chat_message_sent.emit(current_chat)
	# ✅ Only emit type message clicked

func _on_type_message_clicked(chat_name: String) -> void:
	SignalBus.type_message_clicked.emit(current_chat)


func set_current_chat(chat_name: String) -> void:
	if chat_name != current_chat:
		chat_loaded[current_chat] = false
	SignalBus.optional_chats_locked = false  

	current_chat = chat_name
	panel_name.text = chat_name.capitalize()

	var tex_path = "res://assets/character_sprites/portrait_%s.png" % chat_name
	var tex = load(tex_path)
	if tex:
		panel_icon.texture = tex

	var panel_style = StyleBoxFlat.new()
	panel_style.set_corner_radius_all(15)

	if current_chat == "unknown_sender":
		background_chat.color = Color(0.0, 0.0, 0.0, 1.0)
		panel_name.add_theme_color_override("font_color", Color(1,1,1,1))
		panel_style.bg_color = Color(1,1,1,1)
		panel_icon_bg.add_theme_stylebox_override("panel", panel_style)

		if exit_btn:
			exit_btn.visible = false
		if exit_btn_2:
			exit_btn_2.visible = true

		start_flicker()
		load_chat_history(chat_name)
		unknown_sender_opened = true
	else:
		background_chat.color = Color(1,1,1,1)
		panel_name.add_theme_color_override("font_color", Color(0,0,0,1))
		panel_style.bg_color = Color(0.9,0.9,0.9,1)
		panel_icon_bg.add_theme_stylebox_override("panel", panel_style)

		if exit_btn:
			exit_btn.visible = true
		if exit_btn_2:
			exit_btn_2.visible = false

		load_chat_history(chat_name)


func load_chat_history(chat_name: String, force_reload: bool = false) -> void:
	if chat_loaded.get(chat_name, false) and not force_reload:
		return

	# Clear old messages
	for child in chat_container.get_children():
		child.queue_free()

	# Load from ChatManager
	var saved = ChatManager.get_history(chat_name)
	for msg in saved:
		add_message_to_chat(msg["sender"], msg["text"])

	chat_loaded[chat_name] = true

func show_reply_locked_label() -> void:
	var chat_font = FontFile.new()
	chat_font.font_data = load("res://assets/fonts/basis33.ttf")
	
	var locked_label = Label.new()
	locked_label.text = "You can't reply to this conversation."
	locked_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	locked_label.add_theme_font_override("font", chat_font)
	locked_label.add_theme_font_size_override("font_size", 25)
	locked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	locked_label.custom_minimum_size = Vector2(200, 0)

	chat_container.add_child(locked_label)

	await get_tree().process_frame
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _on_exit_pressed() -> void:
	if previous_scene:
		previous_scene.visible = true
	visible = false
	SignalBus.chat_closed.emit(current_chat)
	queue_free()


func start_flicker():
	var tween = create_tween()
	tween.set_loops(-1)

	var color1 = Color(0.104, 0.0, 0.0, 1.0)
	var color2 = Color(0.05, 0.0, 0.0, 1.0)
	var color3 = Color(0.0, 0.0, 0.0, 1.0)

	tween.tween_property(background_chat, "color", color1, 0.8)
	tween.tween_property(background_chat, "color", color2, 0.8)
	tween.tween_property(background_chat, "color", color3, 1.0)
	tween.tween_property(background_chat, "color", color2, 0.8)
	tween.tween_property(background_chat, "color", color1, 0.8)
