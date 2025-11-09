extends Control

@onready var slot_1: Button = $slot_1
@onready var slot_2: Button = $slot_2
@onready var slot_3: Button = $slot_3
@onready var back_button: Button = $back_tips/Panel/Button

var selected_slot: int = 0


func _ready() -> void:
	for i in range(1, 4):
		var slot_node = get_node("slot_%d" % i)
		var tr: TextureRect = slot_node.get_node("TextureRect")
		tr.custom_minimum_size = Vector2(400, 225)
		tr.expand = true
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		
		slot_node.mouse_entered.connect(Callable(self, "_on_slot_hovered").bind(slot_node))
		slot_node.mouse_exited.connect(Callable(self, "_on_slot_unhovered").bind(slot_node))

		_update_slot_ui(i)

	slot_1.pressed.connect(_on_slot_pressed.bind(1))
	slot_2.pressed.connect(_on_slot_pressed.bind(2))
	slot_3.pressed.connect(_on_slot_pressed.bind(3))
	back_button.pressed.connect(_on_back_pressed)

# --- Slot pressed ---
func _on_slot_pressed(slot_number: int) -> void:
	selected_slot = slot_number
	SaveManager.current_slot = slot_number
	SaveManager._set_save_paths()

	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		SaveManager.load_game()
		var scene_menu = load("res://scenes/menu/menu_load_scenes.tscn").instantiate()
		scene_menu.set_slot_save(SaveManager.game_save)
		get_tree().current_scene.add_child(scene_menu)
	else:
		print("Slot %d is empty, cannot load." % slot_number)

# --- Update slot UI ---
func _update_slot_ui(slot_num: int) -> void:
	var slot_path = "user://users/%s_%d/slot_%d/save.res" % [Session.username, Session.user_ID, slot_num]
	var slot_node = get_node("slot_%d" % slot_num)
	var texture_rect = slot_node.get_node("TextureRect")
	var empty_label = slot_node.get_node("empty_slot")
	var date_label = slot_node.get_node("date_created")
	var playtime_label = slot_node.get_node("playtime")
	var current_progress = slot_node.get_node("current_progress")
	var summary_label = slot_node.get_node("summary_label")
	summary_label.visible = false  # hide by default

	if FileAccess.file_exists(slot_path):
		empty_label.visible = false
		date_label.visible = true
		playtime_label.visible = true
		current_progress.visible = true

		var save_data = ResourceLoader.load(slot_path)
		if save_data:
			# --- Date Created ---
			var created_time = save_data.date_created if save_data.date_created != 0 else FileAccess.get_modified_time(slot_path)
			var dt = Time.get_datetime_dict_from_unix_time(created_time)
			dt.hour = (dt.hour + 8) % 24
			var formatted_24h = "%04d-%02d-%02d %02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
			var hour_12 = dt.hour % 12
			if hour_12 == 0: hour_12 = 12
			var ampm = "AM" if dt.hour < 12 else "PM"
			var formatted_12h = "%02d:%02d %s" % [hour_12, dt.minute, ampm]
			date_label.text = "Date Created: %s (%s)" % [formatted_24h, formatted_12h]

			# --- Progress ---
			var act_text = save_data.current_act if save_data.current_act != "" else ""
			var scene_text = save_data.current_scene if save_data.current_scene != "" else ""
			if act_text == "" or scene_text == "":
				for a in save_data.finished_scenes.keys():
					var scenes = save_data.finished_scenes[a]
					if scenes.size() > 0:
						act_text = a
						scene_text = scenes[-1]
						break

			# --- NEW: Override for Act 6 endings ---
			if act_text.to_lower() == "act_6" and (scene_text.to_lower() == "scene_2.1" or scene_text.to_lower() == "scene_2.2"):
				current_progress.text = "The End"
			else:
				current_progress.text = "%s - %s" % [act_text.capitalize(), scene_text.capitalize()] if act_text != "" else "No progress"


			# --- Thumbnail ---
			if act_text != "" and scene_text != "":
				var thumb_path = "res://assets/scenes_thumbnails/%s_%s.png" % [act_text.to_lower(), scene_text.to_lower()]
				if act_text.to_lower() == "act_6" and (scene_text.to_lower() == "scene_2.1" or scene_text.to_lower() == "scene_2.2"):
					thumb_path = "res://assets/scenes_thumbnails/act_6_scene_2.png"
				if ResourceLoader.exists(thumb_path):
					texture_rect.texture = load(thumb_path)

			# --- Playtime ---
			if save_data.playtime_seconds > 0:
				var total_seconds = int(save_data.playtime_seconds)
				var hours = int(total_seconds / 3600)
				var minutes = int((total_seconds % 3600) / 60)
				playtime_label.text = "Playtime: %dh %02dm" % [hours, minutes]
			else:
				playtime_label.text = "Playtime: --"

			# --- Narrative Summary ---
			summary_label.text = _generate_narrative_summary(save_data)

	else:
		# Empty slot
		empty_label.visible = true
		date_label.visible = false
		playtime_label.visible = false
		current_progress.visible = false
		summary_label.text = ""
		texture_rect.texture = null


# --- Hover functions ---
func _on_slot_hovered(slot_node: Node) -> void:
	var summary_label = slot_node.get_node("summary_label")
	var date_label = slot_node.get_node("date_created")
	var playtime_label = slot_node.get_node("playtime")
	var empty_label = slot_node.get_node("empty_slot")
	
	if empty_label.visible:
		summary_label.visible = false
		return
	
	date_label.visible = false
	playtime_label.visible = false
	summary_label.visible = true
	
	_trigger_glitch_effect(slot_node)

func _on_slot_unhovered(slot_node: Node) -> void:
	var summary_label = slot_node.get_node("summary_label")
	var date_label = slot_node.get_node("date_created")
	var playtime_label = slot_node.get_node("playtime")
	var empty_label = slot_node.get_node("empty_slot")
	
	if empty_label.visible:
		summary_label.visible = false
		return
	
	date_label.visible = true
	playtime_label.visible = true
	summary_label.visible = false


func _trigger_glitch_effect(slot_node: Node) -> void:
	var color_rect := slot_node.get_node("ColorRect")
	if not color_rect:
		return

	color_rect.visible = true
	for i in range(3):
		color_rect.visible = not color_rect.visible
		await get_tree().create_timer(0.1).timeout
	color_rect.visible = true

	await get_tree().create_timer(0.1).timeout
	color_rect.visible = false

# --- Generate narrative summary ---
func _generate_narrative_summary(save_data) -> String:
	if not save_data:
		return "No progress yet."

	var act = save_data.current_act
	var scene = save_data.current_scene

	if act == "" or scene == "":
		for a in save_data.finished_scenes.keys():
			var scenes = save_data.finished_scenes[a]
			if scenes.size() > 0:
				act = a
				scene = scenes[-1]
				break

	if act == "" or scene == "":
		return "A brief moment in Danilo's day unfolds."

	var key = "%s_%s" % [act.to_lower(), scene.to_lower()]
	return scene_summaries.get(key, "A brief moment in Danilo's day unfolds.")

# --- Back button ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_back_pressed()
		
func _on_back_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")


# --- Example summaries dictionary ---
var scene_summaries := {
	"act_1_scene_1": "Rain falls as Danilo wakes, lost in thought, can he face what comes next?",
	"act_1_scene_2": "At Rizal Park, memories of a lost friend resurface, will he confront them?",
	"act_1_scene_3": "A shadow from the past lingers in his mind, should he reveal it to Wendy?",
	"act_1_scene_4": "Danilo returns home, memories crowding his mind, can he handle what’s coming next?",
	"act_2_scene_1": "A mysterious message appears from an unknown sender, what truth or danger awaits him?",
	"act_2_scene_2": "Danilo plans a trip to the province to calm his mind, but will escaping really bring peace?",
	"act_2_scene_3": "On Danilo's way home, will he find the answers he seeks?",
	"act_2_scene_4": "Wendy learns Danilo went to the province, but why did he leave so suddenly?",
	"act_3_scene_1": "Danilo returns to his province and receives warnings about the forest, but should he ignore them?",
	"act_3_scene_2": "Danilo reconnects with Wendy and Mira while a mysterious, unsettling message appears, but what does it mean?",
	"act_3_scene_3": "Danilo heads out, but a creeping feeling of being followed won’t leave him. Who—or what—was out there?",
	"act_3_scene_4": "As Danilo finds disturbing clues, what truth is hidden within?",
	"act_4_scene_1": "Danilo ventures into the dark, but what secrets does it hold?",
	"act_4_scene_2": "As Danilo searches for the fragments of Mateo’s diary, what truths will they reveal?",
	"act_4_scene_3": "Danilo explores an chapel filled with shadows and memories, but what lurks in the darkness?",
	"act_4_scene_4": "Danilo follows the wind, racing against time, but what awaits him at the end?",
	"act_5_scene_1": "Danilo returns to the chapel, fearing what he might find, but what secrets will the pages reveal?",
	"act_5_scene_2": "Fragments of Mateo’s diary reveal his fears and secrets, what will Danilo uncover?",
	"act_5_scene_3": "Fragments of Mateo’s diary reveal his fears and secrets, what will Danilo uncover?",
	"act_5_scene_4": "Fragments of Mateo’s diary reveal his fears and secrets, what will Danilo uncover?",
	"act_5_scene_5": "Fragments of Mateo’s diary reveal his fears and secrets, what will Danilo uncover?",
	"act_5_scene_6": "Fragments of Mateo’s diary reveal his fears and secrets, what will Danilo uncover?",
	"act_5_scene_7": "Fragments of Mateo’s diary reveal his fears and secrets, what will Danilo uncover?",
	"act_5_scene_8": "Through Mateo’s diary, Danilo uncovers his memories, will he find peace, or be haunted by what was lost?",
	"act_6_scene_1": "Wendy returns home to search for Danilo, will she find him before it’s too late?",
	"act_6_scene_2.1": "Finally... at rest.",
	"act_6_scene_2.2": "It never ends..."
}

func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
