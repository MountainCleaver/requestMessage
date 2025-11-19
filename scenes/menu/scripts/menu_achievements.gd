extends Control

# ------------------------------------------
#  ACHIEVEMENT DATA
# ------------------------------------------
const ACHIEVEMENTS = [
	{
		#========= ACHIEVEMENT 1 =========#
		"title": "Don’t Look Back",
		"caption": "He’s closer than you think.",
		"description": "Complete Mang Gino's chase without getting caught once.",
		"badge": "res://assets/achievements/achievement_1.png"
	},
	{
		#========= ACHIEVEMENT 2 =========#
		"title": "The Unending Guilt",
		"caption": "It never stopped following you.",
		"description": "Reach the bad ending.",
		"badge": "res://assets/achievements/achievement_2.png"
	},
	{
		#========= ACHIEVEMENT 3 =========#
		"title": "Finally at Rest",
		"caption": "Some peace comes with a price.",
		"description": "Reach the good ending.",
		"badge": "res://assets/achievements/achievement_3.png"
	},
	{
		#========= ACHIEVEMENT 4 =========#
		"title": "Keep the Light Alive",
		"caption": "Darkness only wins if you let it.",
		"description": "Complete the candle mini-game.",
		"badge": "res://assets/achievements/achievement_4.png"
	},
	{
		#========= ACHIEVEMENT 5 =========#
		"title": "Words Left Behind",
		"caption": "He wrote what he couldn’t speak.",
		"description": "Find all of Mateo’s diary pages.",
		"badge": "res://assets/achievements/achievement_5.png"
	},
	{
		#========= ACHIEVEMENT 6 =========#
		"title": "Bitter Comfort",
		"caption": "Comfort comes in tiny doses.",
		"description": "Take all medications.",
		"badge": "res://assets/achievements/achievement_6.png"
	},
	{
		#========= ACHIEVEMENT 7 =========#
		"title": "Unmedicated",
		"caption": "“The ground feels like it’s moving under me...”",
		"description": "Don’t take any medications.",
		"badge": "res://assets/achievements/achievement_7.png"
	},
	{
		#========= ACHIEVEMENT 8 =========#
		"title": "Controlled Breathing",
		"caption": "Breath in... breath out... don’t break.",
		"description": "Complete square breathing mini-game without skipping.",
		"badge": "res://assets/achievements/achievement_8.png"
	},
	{
		#========= ACHIEVEMENT 9 =========#
		"title": "Guiding Light",
		"caption": "“The night feels different with this light in my hands.”",
		"description": "Obtain the flashlight from Lola Ising.",
		"badge": "res://assets/achievements/achievement_9.png"
	},
	{
		#========= ACHIEVEMENT 10 =========#
		"title": "Dim Guidance",
		"caption": "“This light barely cuts through the darkness...”",
		"description": "Unlock the phone flashlight.",
		"badge": "res://assets/achievements/achievement_10.png"
	},
	{
		#========= ACHIEVEMENT 11 =========#
		"title": "Restless By Nature",
		"caption": "“Did I choose the right decision... or am I lost?”",
		"description": "Choose all “restless” choices.",
		"badge": "res://assets/achievements/achievement_11.png"
	},
	{
		#========= ACHIEVEMENT 12 =========#
		"title": "A Moment of Relief",
		"caption": "“It feels lighter... the choices might have been right.”",
		"description": "Choose all “relief” choices.",
		"badge": "res://assets/achievements/achievement_12.png"
	},
	{
		#========= ACHIEVEMENT 13 =========#
		"title": "The One Who Stayed Behind",
		"caption": "You finally saw him... or what’s left of him.",
		"description": "Meet Mateo’s ghost.",
		"badge": "res://assets/achievements/achievement_13.png"
	},
	{
		#========= ACHIEVEMENT 14 =========#
		"title": "Who Are You?",
		"caption": "It watches those who can’t escape themselves.",
		"description": "Encounter the Entity.",
		"badge": "res://assets/achievements/achievement_14.png"
	}
]


# ------------------------------------------
#  NODE REFERENCES
# ------------------------------------------
@onready var list_container = $achievement_holder/MarginContainer/ScrollContainer/VBoxContainer

@onready var achievement_panel = $Panel/achievements
@onready var title_label = $Panel/achievement_title
@onready var caption_label = $Panel/achievement_caption
@onready var desc_label = $Panel/achievement_description
@onready var badge_rect = $Panel/achievement_badge

@onready var back_button: Button = $back_tips/Panel/Button

var shader_material = preload("res://scenes/game/grayscale.tres")
var index := 1

# ------------------------------------------
#  READY
# ------------------------------------------
func _ready() -> void:
	achievement_panel.visible = true
	_generate_achievement_list()
	back_button.pressed.connect(_on_back_pressed)
	
	_refresh_achievements_from_save()
	if SaveManager.game_save:
		print("Unlocked achievements:", SaveManager.game_save.unlocked_achievements)
	else:
		print("No save loaded yet.")

	SignalBus.online_save_merged.connect(_refresh_achievements_from_save)

	Achievements.connect("achievement_unlocked", Callable(self, "_on_achievement_unlocked"))



func _on_achievement_unlocked(id: int, title: String, description: String, badge_path: String) -> void:
	for hbox in list_container.get_children():
		for btn in hbox.get_children():
			if btn.get_meta("id") == id:
				btn.material = null 
				break

# ------------------------------------------
#  GENERATE ACHIEVEMENTS
# ------------------------------------------
func _generate_achievement_list():
	var hbox: HBoxContainer = null
	var index := 1

	var unlocked_ids := []
	for a in SaveManager.game_save.unlocked_achievements:
		unlocked_ids.append(int(a))

	for achievement in ACHIEVEMENTS:
		if (index - 1) % 3 == 0:
			hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 20)
			list_container.add_child(hbox)

		var btn := TextureButton1.new()
		btn.stretch_mode = TextureButton1.STRETCH_KEEP_ASPECT_CENTERED
		btn.texture_normal = load(achievement["badge"])
		btn.set_meta("id", index) 

		if index in unlocked_ids:
			btn.material = null
		else:
			btn.material = shader_material

		btn.pressed.connect(_on_achievement_pressed.bind(index))
		hbox.add_child(btn)
		index += 1

		var glitch_rect := ColorRect.new()
		glitch_rect.visible = false
		glitch_rect.color = Color(1, 1, 1, 1)
		glitch_rect.custom_minimum_size = Vector2(170, 153)
		glitch_rect.position = Vector2(113, 8)
		glitch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Shader
		var glitch_shader := Shader.new()
		glitch_shader.resource_path = "res://scenes/game/act_3/scene_4/glitch_3.gdshader"
		var glitch_mat := ShaderMaterial.new()
		glitch_mat.shader = load("res://scenes/game/act_3/scene_4/glitch_3.gdshader")

		glitch_rect.material = glitch_mat
		btn.add_child(glitch_rect)

		btn.mouse_entered.connect(func():
			glitch_rect.visible = true
			await get_tree().create_timer(0.5).timeout
			glitch_rect.visible = false
		)

		btn.mouse_exited.connect(func():
			glitch_rect.visible = false
		)

		hbox.add_child(btn)


func _refresh_achievements_from_save():
	var unlocked_ids: Array[int] = []

	for a in SaveManager.game_save.unlocked_achievements:
		if typeof(a) == TYPE_STRING:
			unlocked_ids.append(int(a))
		elif typeof(a) == TYPE_INT:
			unlocked_ids.append(a)

	for hbox in list_container.get_children():
		for btn in hbox.get_children():
			var id = btn.get_meta("id")

			if typeof(id) == TYPE_STRING:
				id = id.to_int()
			elif typeof(id) != TYPE_INT:
				continue

			if id in unlocked_ids:
				btn.material = null
			else:
				btn.material = shader_material

				
# ------------------------------------------
#  BUTTON PRESSED
# ------------------------------------------
func _on_achievement_pressed(id: int) -> void:
	var data = ACHIEVEMENTS[id - 1]

	title_label.text = data["title"]
	caption_label.text = data["caption"]

	var unlocked_ids := []
	for a in SaveManager.game_save.unlocked_achievements:
		unlocked_ids.append(int(a))

	if id in [2, 3, 4, 5, 13, 14] and id not in unlocked_ids:
		desc_label.text = "Unlock the achievement to view its description."
	else:
		desc_label.text = data["description"]

	badge_rect.texture = load(data["badge"])
	if id not in unlocked_ids:
		badge_rect.material = shader_material 
	else:
		badge_rect.material = null  

	achievement_panel.visible = false 
	title_label.visible = true
	caption_label.visible = true
	desc_label.visible = true
	badge_rect.visible = true



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
