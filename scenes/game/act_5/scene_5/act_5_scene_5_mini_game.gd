extends Node2D

@onready var npc_gino_with_stick: CharacterBody2D = $decorations/npc_gino_with_stick
@onready var rich_text_label: RichTextLabel = $CanvasLayer/game_over
@onready var count_down: AnimationPlayer = $CanvasLayer/time/count_down

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rich_text_label.hide()
	count_down.play("count_down")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_game_over_body_entered(body: Node2D) -> void:
	if body.name == "npc_gino_with_stick":
		npc_gino_with_stick.scale = Vector2(5.0, 5.0)
		rich_text_label.show()
		SignalBus.next_scene.emit("res://scenes/game/act_5/scene_5/act_5_scene_5_mini_game_start.tscn")

func _start_chase()->void:
	SignalBus.start_chase.emit()
