extends Node2D

@onready var mateo_house = $MateoHouse
@onready var player_danilo = $MateoHouse/player_danilo

func _ready() -> void:
	Hud.phone_intro()

func _on_phone_flashlight_activated() -> void:
	print("Phone flashlight activated — enabling flashlight for player_danilo.")

	# --- Camera stays with the same player ---
	var cam := player_danilo.get_node_or_null("Camera2D")
	if cam:
		cam.make_current()
	else:
		print("⚠️ Warning: Camera2D not found in player_danilo.")

	# --- Enable flashlight directly on existing player ---
	var phone_flashlight = player_danilo.get_node_or_null("phone_flashlight")
	if phone_flashlight:
		phone_flashlight.visible = true
		print("✅ Flashlight enabled successfully.")
	else:
		print("⚠️ Warning: phone_flashlight node not found under player_danilo.")

	print("✅ Flashlight mode active — player and position retained.")
