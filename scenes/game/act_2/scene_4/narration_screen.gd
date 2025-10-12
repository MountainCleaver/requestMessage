extends CanvasLayer

@onready var text_label: RichTextLabel = $ColorRect/RichTextLabel
@onready var color_rect: ColorRect = $ColorRect
@onready var sfx_player: AudioStreamPlayer = $TYPINGSOUNDS

# === CONFIGURABLE VARIABLES ===
var narration_text := """Back in Manila, Wendy scrolls through her messages.
Nothing from Danilo.
She checks the group chat.
Still quiet."""
var typing_speed := 0.05 
var sfx_interval := 2    
var is_outro := false
signal narration_finished

func _ready() -> void:
	text_label.text = ""
	color_rect.visible = true
	color_rect.modulate.a = 1.0

	text_label.bbcode_enabled = true 

	_type_text(narration_text)

func set_narration_text(text: String, outro: bool = false) -> void:
	narration_text = text
	is_outro = outro

func _type_text(text: String) -> void:
	await get_tree().process_frame
	

	# Clear the text first
	text_label.text = ""
	
	# We need to manually handle BBCode parsing during typing

	var current_text := ""
	var inside_tag := false
	var current_tag := ""
	
	for i in range(text.length()):
		var char = text[i]
		
		# Handle BBCode tags
		if char == "[":
			inside_tag = true
			current_tag = "["
			continue
		elif char == "]" and inside_tag:
			current_tag += "]"
			inside_tag = false
			# Apply the tag immediately
			text_label.text += current_tag
			current_text += current_tag
			continue
		
		if inside_tag:
			current_tag += char
			continue
		
		# Regular character - add to display
		current_text += char
		text_label.text = current_text
		
		# Typing delay logic
		var delay = typing_speed
		if char in [".", "!", "?", "…"]:
			delay = typing_speed * 8 
		elif char == ",":
			delay = typing_speed * 2 
		elif char == " " or char == "\n":
			delay = typing_speed * 1.5 

		if not char in [" ", "\n", ".", ",", "!", "?", "…"] and sfx_player:
			if i % sfx_interval == 0:
				sfx_player.pitch_scale = randf_range(0.95, 1.05)
				sfx_player.play()

		await get_tree().create_timer(delay).timeout

	# Wait a bit to let the effects be visible
	await get_tree().create_timer(1.5).timeout
	_fade_out()

func _fade_out() -> void:
	var fade_time := 1.0
	var tween := get_tree().create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, fade_time)
	tween.tween_callback(Callable(self, "_on_fade_complete"))

func _on_fade_complete() -> void:
	color_rect.visible = false
	emit_signal("narration_finished")
	
	if is_outro:
		SignalBus.emit_signal("outro_narration_finished")
	
	queue_free()
