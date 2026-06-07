extends Node

const NarrationPanelScene = preload("res://helpers/narration_panel.tscn")
var panel_instance: CanvasLayer = null

var _is_typing: bool = false
var _continue_pressed: bool = false

# === EXTRA CONFIGURABLES (from narration_screen) ===
var typing_speed := 0.05
var sfx_interval := 2
var _sfx_counter := 0
var sfx_player: AudioStreamPlayer = null


func _ensure_panel() -> void:
	if panel_instance == null:
		panel_instance = NarrationPanelScene.instantiate()
		panel_instance.visible = false
		get_tree().current_scene.add_child(panel_instance)
		
		# Connect continue button
		if panel_instance.has_node("Control/Panel/TextureRect/Button"):
			var btn = panel_instance.get_node("Control/Panel/TextureRect/Button")
			btn.visible = false
			btn.pressed.connect(_on_continue_pressed)
		
		# Use your existing SFXTypewriter node
		if panel_instance.has_node("SFXTypewriter"):
			sfx_player = panel_instance.get_node("SFXTypewriter")


func _ensure_panel_async() -> void:
	_ensure_panel()
	await get_tree().process_frame


func show_narration_typewriter(lines: Array, speed: float = 0.05) -> void:
	await _ensure_panel_async()
	if not is_instance_valid(panel_instance):
		return
	
	_is_typing = true
	_continue_pressed = false

	var label: RichTextLabel = panel_instance.get_node("Control/Panel/TextureRect/RichTextLabel")
	var button: Button = panel_instance.get_node("Control/Panel/TextureRect/Button")
	label.text = ""
	panel_instance.visible = true
	button.visible = true
	button.text = "Skip"

	var full_text = ""
	for i in range(lines.size()):
		full_text += lines[i]
		if i < lines.size() - 1:
			full_text += "\n"

	var current_text := ""
	var inside_tag := false
	var current_tag := ""

	for i in range(full_text.length()):
		if not is_instance_valid(panel_instance):
			return
		if _continue_pressed:
			label.text = full_text
			_is_typing = false
			break

		var char = full_text[i]

		if char == "[":
			inside_tag = true
			current_tag = "["
			continue
		elif char == "]" and inside_tag:
			current_tag += "]"
			inside_tag = false
			current_text += current_tag
			if is_instance_valid(label):
				label.text = current_text
			continue
		elif inside_tag:
			current_tag += char
			continue

		current_text += char
		if is_instance_valid(label):
			label.text = current_text

		var delay := speed
		if char in [".", "!", "?", "…"]:
			delay = speed * 8
		elif char == ",":
			delay = speed * 2
		elif char == " " or char == "\n":
			delay = speed * 1.5

		if not char in [" ", "\n", ".", ",", "!", "?", "…"] and sfx_player and is_instance_valid(sfx_player):
			if _sfx_counter % sfx_interval == 0:
				sfx_player.pitch_scale = randf_range(0.95, 1.05)
				sfx_player.play()
			_sfx_counter += 1

		await get_tree().create_timer(delay).timeout

	if not is_instance_valid(panel_instance):
		return

	_is_typing = false
	_continue_pressed = false 
	button.text = "Click to Continue"

	while not _continue_pressed and is_instance_valid(panel_instance):
		await get_tree().process_frame

	await hide_narration()


func _unhandled_input(event):
	if event.is_action_pressed("dialog_next"):
		_on_continue_pressed()


func _on_continue_pressed():
	_continue_pressed = true


func hide_narration() -> void:
	if not is_instance_valid(panel_instance):
		return
	
	# === FADE OUT (AnimationPlayer or fallback) ===
	if panel_instance.has_node("AnimationPlayer"):
		var anim = panel_instance.get_node("AnimationPlayer")
		if anim.has_animation("fade_out"):
			anim.play("fade_out")
			await anim.animation_finished
	else:
		if is_instance_valid(panel_instance):
			var tween := get_tree().create_tween()
			tween.tween_property(panel_instance, "modulate:a", 0.0, 1.0)
			await tween.finished
	
	if is_instance_valid(panel_instance):
		panel_instance.queue_free()
	panel_instance = null
		
