extends Control

@onready var slot_1: Button = $slot_1
@onready var slot_2: Button = $slot_2
@onready var slot_3: Button = $slot_3
@onready var back_button: Button = $back_tips/Panel/Button

var selected_slot: int = 0

func _ready() -> void:
	_update_slot_ui(1)
	_update_slot_ui(2)
	_update_slot_ui(3)

	slot_1.pressed.connect(_on_slot_pressed.bind(1))
	slot_2.pressed.connect(_on_slot_pressed.bind(2))
	slot_3.pressed.connect(_on_slot_pressed.bind(3))

	back_button.pressed.connect(_on_back_pressed)

func _on_slot_pressed(slot_number: int) -> void:
	selected_slot = slot_number
	SaveManager.current_slot = slot_number
	SaveManager._set_save_paths()

	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		SaveManager.load_game()
		var scene_menu = load("res://scenes/menu/menu_load_scenes.tscn").instantiate()
		scene_menu.set_slot_save(SaveManager.game_save)  # pass slot-specific save
		get_tree().current_scene.add_child(scene_menu)
	else:
		print("Slot %d is empty, cannot load." % slot_number)

func _update_slot_ui(slot_num: int) -> void:
	var slot_path = "user://users/%s_%d/slot_%d/save.res" % [Session.username, Session.user_ID, slot_num]
	var slot_node = get_node("slot_%d" % slot_num)
	var texture_rect = slot_node.get_node("TextureRect")
	var empty_label = slot_node.get_node("empty_slot")
	var date_label = slot_node.get_node("date_created")
	var last_played_label = slot_node.get_node("last_played")
	var playtime_label = slot_node.get_node("playtime")
	var current_progress = slot_node.get_node("current_progress")

	if FileAccess.file_exists(slot_path):
		empty_label.visible = false
		date_label.visible = true
		last_played_label.visible = true
		playtime_label.visible = true
		current_progress.visible = true

		var save_data = ResourceLoader.load(slot_path)
		if save_data:
			# --- Date Created from save ---
			var created_time = save_data.date_created if save_data.date_created != 0 else FileAccess.get_modified_time(slot_path)
			var dt = Time.get_datetime_dict_from_unix_time(created_time)
			dt.hour = (dt.hour + 8) % 24  # PH time
			var formatted_24h = "%04d-%02d-%02d %02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
			var hour_12 = dt.hour % 12
			if hour_12 == 0:
				hour_12 = 12
			var ampm = "AM" if dt.hour < 12 else "PM"
			var formatted_12h = "%02d:%02d %s" % [hour_12, dt.minute, ampm]
			date_label.text = "Date Created: %s (%s)" % [formatted_24h, formatted_12h]

			# --- Last Played using file mod time ---
			var mod_time = FileAccess.get_modified_time(slot_path)
			dt = Time.get_datetime_dict_from_unix_time(mod_time)
			dt.hour = (dt.hour + 8) % 24
			formatted_24h = "%04d-%02d-%02d %02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
			hour_12 = dt.hour % 12
			if hour_12 == 0:
				hour_12 = 12
			ampm = "AM" if dt.hour < 12 else "PM"
			formatted_12h = "%02d:%02d %s" % [hour_12, dt.minute, ampm]
			last_played_label.text = "Last Played: %s (%s)" % [formatted_24h, formatted_12h]

			# --- Progress ---
			var act_text = str(save_data.current_act) if save_data.current_act != "" else ""
			var scene_text = str(save_data.current_scene) if save_data.current_scene != "" else ""

			if act_text == "" and scene_text == "":
				for a in save_data.finished_scenes.keys():
					var scenes = save_data.finished_scenes[a]
					if scenes.size() > 0:
						act_text = a
						scene_text = str(scenes[-1])
						break

			current_progress.text = "%s - %s" % [act_text.capitalize(), scene_text.capitalize()] if act_text != "" else "No progress"

			# --- Thumbnail ---
			var thumb_path := ""
			if act_text != "" and scene_text != "":
				thumb_path = "res://assets/scenes_thumbnails/%s_%s.png" % [act_text.to_lower(), scene_text.to_lower()]

			texture_rect.texture = load(thumb_path) if thumb_path != "" and ResourceLoader.exists(thumb_path) else load("res://assets/main menu/slot_placeholder.png")

			# --- Playtime ---
			if save_data.playtime_seconds > 0:
				var total_seconds = int(save_data.playtime_seconds)
				var hours = int(total_seconds / 3600)
				var minutes = int((total_seconds % 3600) / 60)
				playtime_label.text = "Playtime: %dh %02dm" % [hours, minutes]
			else:
				playtime_label.text = "Playtime: --"
		else:
			empty_label.visible = true
			date_label.visible = false
			last_played_label.visible = false
			playtime_label.visible = false
			current_progress.visible = false
			texture_rect.texture = load("res://assets/main menu/slot_placeholder.png")
	else:
		empty_label.visible = true
		date_label.visible = false
		last_played_label.visible = false
		playtime_label.visible = false
		current_progress.visible = false
		texture_rect.texture = load("res://assets/main menu/slot_placeholder.png")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
