extends Area2D

var A_4S_4: Resource

@export var diary_note: Sprite2D
var player_in_range := false
static var note_collected := false

var scene_objectives = [
	{"ID": 3, "text": "Leave the cliff"}
]

func get_note_image() -> Sprite2D:
	return diary_note

func _ready():
	_load_dialogue()
	monitoring = true
	set_deferred("monitorable", true)
	set_process(true)
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_4/scene_4/a4s4_en.dialogue"
	else:
		path = "res://dialogues/act_4/scene_4/a4s4.dialogue"
	
	A_4S_4 = load(path)
	
func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		SignalBus.in_npc.emit("Press [E] to read the paper")

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		SignalBus.out_npc.emit("clear")

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		SignalBus.out_npc.emit("clear")
		ObjectiveManager.complete_objective(2)

		if Hud.has_method("mark_objective_done"):
			Hud.mark_objective_done()
		DialogueManager.show_dialogue_balloon(A_4S_4, "after_found_paper")
		ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
		note_collected = true
		call_deferred("queue_free")
