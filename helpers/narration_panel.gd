extends Node

const NarrationPanelScene = preload("res://helpers/narration_panel.tscn")
var panel_instance: Control = null

var _is_typing: bool = false
var _continue_pressed: bool = false

func _ensure_panel() -> void:
	if panel_instance == null:
		panel_instance = NarrationPanelScene.instantiate()
		panel_instance.visible = false
		get_tree().current_scene.add_child(panel_instance)
		
		if panel_instance.has_node("Panel/TextureRect/Button"):
			var btn = panel_instance.get_node("Panel/TextureRect/Button")
			btn.visible = false
			btn.pressed.connect(_on_continue_pressed)

func _ensure_panel_async() -> void:
	_ensure_panel()
	await get_tree().process_frame


func show_narration_typewriter(lines: Array, speed: float = 0.05) -> void:
	await _ensure_panel_async()
	_is_typing = true
	_continue_pressed = false
	
	var label = panel_instance.get_node("Panel/TextureRect/Label")
	var button = panel_instance.get_node("Panel/TextureRect/Button")
	label.text = ""
	panel_instance.visible = true
	button.visible = false
	
	# Optional fade-in animation
	if panel_instance.has_node("AnimationPlayer"):
		var anim = panel_instance.get_node("AnimationPlayer")
		if anim.has_animation("fade_in"):
			anim.play("fade_in")
			await anim.animation_finished
	
	for line in lines:
		var typed = ""
		for i in line.length():
			if not _is_typing:
				break
			typed += line[i]
			label.text = label.text + line[i]  # Add new char
			await get_tree().create_timer(speed).timeout
		
		# End of line → add a newline
		label.text += "\n"
	
	# Finished typing all lines
	_is_typing = false
	button.visible = true
	
	# Wait until the player presses "Continue"
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
		panel_instance.visible = false
