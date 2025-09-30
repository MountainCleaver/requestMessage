extends Control

@onready var gridcontainer: GridContainer = $ScrollContainer/MarginContainer/gridcontainer
@onready var button: Button = $back_tips/Panel/Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var data = SaveManager.game_save.finished_scenes
	print(data)
	
	for act in data.keys():
		var scenes: Array = data[act]
		if scenes.is_empty():
			continue
		
		for scene in scenes:
			_create_button(act, scene)


func _create_button(act: String, scene: String) -> void:
	var button = Button.new()
	var texture = load("res://assets/scenes_thumbnails/%s_%s.png" % [act, scene])
	if texture:
		button.icon = texture
	button.text = "%s %s" % [act, scene]
	button.connect("pressed", Callable(self, "_on_scene_button_pressed").bind(act, scene))
	
	gridcontainer.add_child(button)


func _on_scene_button_pressed(act: String, scene: String) -> void:
	if BgmManager:
		BgmManager.stop_music()
	var path : String = "res://scenes/game/%s/%s/%s_%s.tscn" % [act, scene, act, scene]

	# Track save using SaveManager (total saves only)
	SaveManager.track_save()

	SignalBus.next_scene.emit(path)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_exit_pressed()


func _on_exit_pressed() -> void:
	SignalBus.exit_overlay.emit()
	queue_free()
