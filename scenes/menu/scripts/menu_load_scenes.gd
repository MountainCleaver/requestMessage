extends Control

@onready var gridcontainer: GridContainer = $ScrollContainer/MarginContainer/gridcontainer
@onready var back_button: Button = $back_tips/Panel/Button

var slot_save: SaveGameResource = null

func _ready() -> void:
	back_button.pressed.connect(_on_exit_pressed)


# Called from menu_load_game_slots after slot is selected
func set_slot_save(save_resource: SaveGameResource) -> void:
	slot_save = save_resource
	call_deferred("_refresh_grid")  # ensures GridContainer exists


func _refresh_grid() -> void:
	if not gridcontainer:
		print("GridContainer STILL not ready, retrying...")
		call_deferred("_refresh_grid")
		return

	# Clear previous buttons
	for child in gridcontainer.get_children():
		child.queue_free()

	if not slot_save:
		print("No save loaded for this slot")
		return

	# Keep track of added buttons to avoid duplicates
	var added_scenes := {}

	for act in slot_save.finished_scenes.keys():
		var scenes: Array = slot_save.finished_scenes[act]
		for scene in scenes:
			_create_button(act, scene)
			added_scenes["%s_%s" % [act, scene]] = true

	# Add current scene if not finished yet
	if slot_save.current_act != "" and slot_save.current_scene != "":
		var key = "%s_%s" % [slot_save.current_act, slot_save.current_scene]
		if not added_scenes.has(key):
			_create_button(slot_save.current_act, slot_save.current_scene)



func _create_button(act: String, scene: String) -> void:
	var button = Button.new()
	var texture_path = "res://assets/scenes_thumbnails/%s_%s.png" % [act, scene]

	if ResourceLoader.exists(texture_path):
		button.icon = load(texture_path)
	
	button.text = "%s %s" % [act.capitalize(), scene.capitalize()]
	button.connect("pressed", Callable(self, "_on_scene_button_pressed").bind(act, scene))

	gridcontainer.add_child(button)


func _on_scene_button_pressed(act: String, scene: String) -> void:
	if BgmManager:
		BgmManager.stop_music()

	var path = "res://scenes/game/%s/%s/%s_%s.tscn" % [act, scene, act, scene]

	# Track save
	SaveManager.track_save()

	SignalBus.next_scene.emit(path)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_exit_pressed()


func _on_exit_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_load_game_slots.tscn")
