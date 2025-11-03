extends Area2D

@export var wind_direction: Vector2 = Vector2.RIGHT
@export var wind_strength: float = 60.0
@onready var wind_sprite: AnimatedSprite2D = $wind2
@onready var sfx_wind: Node = $SFXWind
var A_4S_4: Resource

func _ready():
	_load_dialogue()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if wind_sprite:
		wind_sprite.show()
	if sfx_wind:
		sfx_wind.show()

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_4/scene_4/a4s4_en.dialogue"
	else:
		path = "res://dialogues/act_4/scene_4/a4s4.dialogue"
	A_4S_4 = load(path)

func _on_body_entered(body: Node2D):
	print("Entered wind area: ", body)
	if body.is_in_group("player") and body.has_method("apply_wind"):
		var entered_from_windward: bool = body.global_position.x > global_position.x
		body.set_meta("entered_from_windward", entered_from_windward)

		if entered_from_windward:
			body.apply_wind(wind_direction * wind_strength, self)
			print("Entered from windward: wind applied.")
			if wind_sprite:
				wind_sprite.show()
			if sfx_wind:
				sfx_wind.show()
		else:
			print("Entered from lee: wind NOT applied.")
			if wind_sprite:
				wind_sprite.hide()
			if sfx_wind:
				sfx_wind.stop()

func _on_body_exited(body: Node2D):
	print("Exited wind area: ", body)

	if body.is_in_group("player") and body.has_method("remove_wind"):
		var entered_from_windward: bool = body.get_meta("entered_from_windward", false)
		var exited_to_windward: bool = body.global_position.x > global_position.x

		if entered_from_windward and not exited_to_windward:
			body.remove_wind(self)
			Hud.show_objectives()
			print("Exited to lee side: wind removed and wind area destroyed.")
			if wind_sprite:
				wind_sprite.hide()
			if sfx_wind:
				sfx_wind.stop()
			queue_free()
		else:
			print("Exited to windward side: keep wind active.")
			if wind_sprite:
				wind_sprite.show()
			if sfx_wind:
				sfx_wind.show()

		body.set_meta("entered_from_windward", false)
