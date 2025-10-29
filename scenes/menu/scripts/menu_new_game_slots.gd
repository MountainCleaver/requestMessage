extends Control

@onready var slot_1: Button = $slot_1
@onready var slot_2: Button = $slot_2
@onready var slot_3: Button = $slot_3
@onready var button: Button = $back_tips/Panel/Button
@onready var overwrite_dialog: ConfirmationDialog = $overwriteConfirmationDialog
@onready var newsave_dialog: ConfirmationDialog = $newsaveConfirmationDialog

var selected_slot: int = 0

func _ready() -> void:
	for i in range(1, 4):
		var slot_node: Button = get_node("slot_%d" % i)
		var tr: TextureRect = slot_node.get_node("TextureRect")
		tr.custom_minimum_size = Vector2(400, 225)
		tr.expand = true
		tr.stretch_mode = TextureRect.STRETCH_SCALE

		slot_node.mouse_entered.connect(Callable(self, "_on_slot_hovered").bind(slot_node, i))
		slot_node.mouse_exited.connect(Callable(self, "_on_slot_unhovered").bind(slot_node, i))
		_update_slot_ui(i)

	slot_1.pressed.connect(_on_slot_pressed.bind(1))
	slot_2.pressed.connect(_on_slot_pressed.bind(2))
	slot_3.pressed.connect(_on_slot_pressed.bind(3))

	button.pressed.connect(_on_back_pressed)
	newsave_dialog.confirmed.connect(_on_newsave_confirmed)
	overwrite_dialog.confirmed.connect(_on_overwrite_confirmed)


func _on_slot_pressed(slot_number: int) -> void:
	selected_slot = slot_number
	SaveManager.current_slot = slot_number
	SaveManager._set_save_paths()

	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		overwrite_dialog.dialog_text = "WARNING: Slot %d already contains saved progress.\nOverwriting will ERASE all existing data in this slot.\n\nDo you want to continue?" % slot_number
		overwrite_dialog.popup_centered()
	else:
		newsave_dialog.dialog_text = "Slot %d is empty.\nDo you want to create a new save file here?" % slot_number
		newsave_dialog.popup_centered()



func _on_newsave_confirmed() -> void:
	print("Creating new game in slot %d" % selected_slot)
	SaveManager.current_slot = selected_slot
	SaveManager.reset_save_state()
	
	if SaveManager.game_save.date_created == 0:
		SaveManager.game_save.date_created = Time.get_unix_time_from_system()
	
	SaveManager.save_game()
	
	if Session.user_ID != 0:
		print("[MenuLoad] Pushing new save online for user:", Session.user_ID)
		SaveManager._push_online_save(
			SaveManager.game_save.current_act,
			SaveManager.game_save.current_scene
		)
	
	if BgmManager:
		BgmManager.stop_music()
	
	SignalBus.next_scene.emit("res://scenes/game/act_1_title_scene.tscn")



func _on_overwrite_confirmed() -> void:
	print("Overwriting slot %d" % selected_slot)
	
	SaveManager.current_slot = selected_slot
	SaveManager.reset_save_state()
	SaveManager.game_save.date_created = Time.get_unix_time_from_system()
	SaveManager.save_game()
	
	if Session.user_ID != 0:
		print("[MenuLoad] Uploading overwritten save online for user:", Session.user_ID)
		SaveManager._push_online_save(
			SaveManager.game_save.current_act,
			SaveManager.game_save.current_scene
		)
	else:
		print("[MenuLoad] Skipped online push: user not logged in.")
	
	if BgmManager:
		BgmManager.stop_music()
	
	SignalBus.next_scene.emit("res://scenes/game/act_1_title_scene.tscn")




func _update_slot_ui(slot_num: int) -> void:
	var slot_path = "user://users/%s_%d/slot_%d/save.res" % [Session.username, Session.user_ID, slot_num]
	var slot_node = get_node("slot_%d" % slot_num)
	var texture_rect = slot_node.get_node("TextureRect")
	var empty_label = slot_node.get_node("empty_slot")
	var date_label = slot_node.get_node("date_created")
	var playtime_label = slot_node.get_node("playtime")
	var current_progress = slot_node.get_node("current_progress")
	var summary_label = slot_node.get_node("summary_label")
	summary_label.visible = false
	summary_label.text = "Hover to see summary."

	if FileAccess.file_exists(slot_path):
		var save_data = ResourceLoader.load(slot_path)
		if save_data:
			empty_label.visible = false
			date_label.visible = true
			playtime_label.visible = true
			current_progress.visible = true

			var created_time = save_data.date_created if save_data.date_created != 0 else FileAccess.get_modified_time(slot_path)
			var dt = Time.get_datetime_dict_from_unix_time(created_time)
			dt.hour = (dt.hour + 8) % 24
			var formatted_24h = "%04d-%02d-%02d %02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
			var hour_12 = dt.hour % 12
			if hour_12 == 0: hour_12 = 12
			var ampm = "AM" if dt.hour < 12 else "PM"
			var formatted_12h = "%02d:%02d %s" % [hour_12, dt.minute, ampm]
			date_label.text = "Date Created: %s (%s)" % [formatted_24h, formatted_12h]

			var act_text = str(save_data.current_act)
			var scene_text = str(save_data.current_scene)
			if act_text == "" and scene_text == "":
				for a in save_data.finished_scenes.keys():
					var scenes = save_data.finished_scenes[a]
					if scenes.size() > 0:
						act_text = a
						scene_text = str(scenes[-1])
						break

			current_progress.text = "%s - %s" % [act_text.capitalize(), scene_text.capitalize()] if act_text != "" else "No progress"

			var thumb_path := ""
			if act_text != "" and scene_text != "":
				thumb_path = "res://assets/scenes_thumbnails/%s_%s.png" % [act_text.to_lower(), scene_text.to_lower()]
			texture_rect.texture = load(thumb_path) if thumb_path != "" and ResourceLoader.exists(thumb_path) else load("res://assets/main menu/slot_placeholder.png")

			if save_data.playtime_seconds > 0:
				var total_seconds = int(save_data.playtime_seconds)
				var hours = total_seconds / 3600
				var minutes = (total_seconds % 3600) / 60
				playtime_label.text = "Playtime: %dh %02dm" % [hours, minutes]
			else:
				playtime_label.text = "Playtime: --"

			slot_node.set_meta("summary_text", _generate_narrative_summary(save_data))
		else:
			_set_empty_slot_ui(empty_label, date_label, playtime_label, current_progress, texture_rect)
	else:
		_set_empty_slot_ui(empty_label, date_label, playtime_label, current_progress, texture_rect)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
	
func _set_empty_slot_ui(empty_label, date_label, playtime_label, current_progress, texture_rect):
	empty_label.visible = true
	date_label.visible = false
	playtime_label.visible = false
	current_progress.visible = false
	texture_rect.texture = load("res://assets/main menu/slot_placeholder.png")

func _on_slot_hovered(slot_node: Node, slot_num: int) -> void:
	var summary_label = slot_node.get_node("summary_label")
	var date_label = slot_node.get_node("date_created")
	var playtime_label = slot_node.get_node("playtime")
	date_label.visible = false
	playtime_label.visible = false
	summary_label.visible = true

	var summary_text = slot_node.get_meta("summary_text", "No progress yet.")
	summary_label.text = summary_text


func _on_slot_unhovered(slot_node: Node, slot_num: int) -> void:
	var summary_label = slot_node.get_node("summary_label")
	var date_label = slot_node.get_node("date_created")
	var playtime_label = slot_node.get_node("playtime")
	date_label.visible = true
	playtime_label.visible = true
	summary_label.visible = false


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


# --- Scene summaries dictionary ---
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
	"act_4_scene_3": "Danilo explores a chapel filled with shadows and memories, but what lurks in the darkness?",
	"act_4_scene_4": "Danilo follows the wind, racing against time, but what awaits him at the end?",
	"act_5_scene_1": "Danilo returns to the chapel, fearing what he might find, but what secrets will the pages reveal?",
	"act_5_scene_8": "Through Mateo’s diary, Danilo uncovers his memories, will he find peace, or be haunted by what was lost?",
	"act_6_scene_1": "Wendy returns home to search for Danilo, will she find him before it’s too late?"
}
