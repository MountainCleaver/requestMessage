extends Control

@onready var gridcontainer: GridContainer = $ScrollContainer/MarginContainer/gridcontainer
@onready var back_button: Button = $back_tips/Panel/Button
@onready var overwrite_dialog: ConfirmationDialog = $overwriteConfirmationDialog

var slot_save: SaveGameResource = null
var pending_act: String = ""
var pending_scene: String = ""

func _ready() -> void:
	back_button.pressed.connect(_on_exit_pressed)
	overwrite_dialog.connect("confirmed", _on_overwrite_confirmed)

func set_slot_save(save_resource: SaveGameResource) -> void:
	slot_save = save_resource
	call_deferred("_refresh_grid")

func _refresh_grid() -> void:
	if not gridcontainer:
		call_deferred("_refresh_grid")
		return

	for child in gridcontainer.get_children():
		child.queue_free()

	if not slot_save:
		return

	var added_scenes := {}

	var sorted_acts = slot_save.finished_scenes.keys()
	sorted_acts.sort()
	sorted_acts.reverse()

	for act in sorted_acts:
		var scenes: Array = slot_save.finished_scenes[act]
		scenes.sort()
		scenes.reverse()
		for scene in scenes:
			_create_button(act, scene)
			added_scenes["%s_%s" % [act, scene]] = true

	if slot_save.current_act != "" and slot_save.current_scene != "":
		var key = "%s_%s" % [slot_save.current_act, slot_save.current_scene]
		if not added_scenes.has(key):
			_create_button(slot_save.current_act, slot_save.current_scene)

func _create_button(act: String, scene: String) -> void:
	var button = Button.new()
	button.custom_minimum_size = Vector2(400, 225) 
	button.expand_icon = true

	var texture_path = "res://assets/scenes_thumbnails/%s_%s.png" % [act, scene]
	if ResourceLoader.exists(texture_path):
		button.icon = load(texture_path)

	button.text = "%s %s" % [act.capitalize(), scene.capitalize()]
	button.connect("pressed", Callable(self, "_on_scene_button_pressed").bind(act, scene))

	gridcontainer.add_child(button)

func _on_scene_button_pressed(act: String, scene: String) -> void:
	pending_act = act
	pending_scene = scene

	var latest_act = ""
	var latest_scene = ""
	var acts_sorted = slot_save.finished_scenes.keys()
	acts_sorted.sort()
	for a in acts_sorted:
		var scns = slot_save.finished_scenes[a]
		scns.sort()
		for s in scns:
			latest_act = a
			latest_scene = s

	if act == latest_act and scene == latest_scene:
		_load_scene(act, scene)
		return

	if slot_save.finished_scenes.has(act) and scene in slot_save.finished_scenes[act]:
		var erased_scenes := []
		for a in acts_sorted:
			var scns = slot_save.finished_scenes[a]
			scns.sort()
			for s in scns:
				if a > act or (a == act and s > scene):
					erased_scenes.append("%s %s" % [a.capitalize(), s.capitalize()])

		var warning_text = "Scene %s %s has already been completed.\n" % [act.capitalize(), scene.capitalize()]
		if erased_scenes.size() > 0:
			warning_text += "WARNING: Selecting this scene will ERASE progress in later scenes:\n"

			for i in range(min(erased_scenes.size(), 5)):
				warning_text += " - %s\n" % erased_scenes[i]

			if erased_scenes.size() > 5:
				warning_text += " ...and %d more\n" % (erased_scenes.size() - 5)

		warning_text += "Do you want to continue and overwrite progress?"

		overwrite_dialog.dialog_text = warning_text
		overwrite_dialog.min_size = Vector2(600, 300)
		overwrite_dialog.popup_centered()

func _on_overwrite_confirmed() -> void:
	if pending_act == "" or pending_scene == "":
		return

	var acts_sorted = slot_save.finished_scenes.keys()
	acts_sorted.sort()
	
	var reached = false

	for act in acts_sorted:
		var scenes = slot_save.finished_scenes[act]
		scenes.sort()

		var new_scenes = []

		for scene in scenes:
			if not reached:
				if act == pending_act and scene == pending_scene:
					reached = true
					new_scenes.append(scene)
				elif act < pending_act or (act == pending_act and scene < pending_scene):
					new_scenes.append(scene)

		if new_scenes.size() > 0:
			slot_save.finished_scenes[act] = new_scenes
		else:
			slot_save.finished_scenes.erase(act)

	slot_save.current_act = pending_act
	slot_save.current_scene = pending_scene
	
	if Hud:
		await get_tree().process_frame
		Hud.reset_phone_dont_show()
		
	SaveManager.game_save = slot_save
	SaveManager.save_game()

	if Session.user_ID != 0:
		SaveManager._push_online_save(pending_act, pending_scene)

	_load_scene(pending_act, pending_scene)

	pending_act = ""
	pending_scene = ""

func _load_scene(act: String, scene: String) -> void:
	if BgmManager:
		BgmManager.stop_music()

	var path = "res://scenes/game/%s/%s/%s_%s.tscn" % [act, scene, act, scene]

	# Track save
	SaveManager.track_save()
	
	if Hud:
		await get_tree().process_frame
		Hud.reset_phone_dont_show()
		
	SignalBus.next_scene.emit(path)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_exit_pressed()

func _on_exit_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_load_game_slots.tscn")
