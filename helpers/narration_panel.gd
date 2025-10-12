extends Node

const NarrationPanelScene = preload("res://helpers/narration_panel.tscn")
var panel_instance: CanvasLayer = null

var _is_typing: bool = false
var _continue_pressed: bool = false


func _ensure_panel() -> void:
	if panel_instance == null:
		panel_instance = NarrationPanelScene.instantiate()
		panel_instance.visible = false
		
		# ✅ CHANGED: add_child() directly, since CanvasLayer is already UI layer
		get_tree().root.add_child(panel_instance)
		
		if panel_instance.has_node("Control/Panel/TextureRect/Button"):
			var btn = panel_instance.get_node("Control/Panel/TextureRect/Button")
			btn.visible = false
			btn.pressed.connect(_on_continue_pressed)


func _ensure_panel_async() -> void:
	_ensure_panel()
	await get_tree().process_frame


func show_narration_typewriter(lines: Array, speed: float = 0.05) -> void:
	await _ensure_panel_async()
	_is_typing = true
	_continue_pressed = false

	var label: Label = panel_instance.get_node("Control/Panel/TextureRect/Label")
	var button: Button = panel_instance.get_node("Control/Panel/TextureRect/Button")

	label.text = ""
	panel_instance.visible = true
	button.visible = false

	if panel_instance.has_node("AnimationPlayer"):
		var anim: AnimationPlayer = panel_instance.get_node("AnimationPlayer")
		if anim.has_animation("fade_in"):
			anim.play("fade_in")
			await anim.animation_finished

	for line in lines:
		for i in line.length():
			if not _is_typing:
				break
			label.text += line[i]
			await get_tree().create_timer(speed).timeout
		label.text += "\n"

	_is_typing = false
	button.visible = true

	while not _continue_pressed:
		await get_tree().process_frame


func _on_continue_pressed():
	_continue_pressed = true


func hide_narration() -> void:
	if panel_instance:
		if panel_instance.has_node("AnimationPlayer"):
			var anim = panel_instance.get_node("AnimationPlayer")
			if anim.has_animation("fade_out"):
				anim.play("fade_out")
				await anim.animation_finished
		panel_instance.queue_free()  # Free it
		panel_instance = null
