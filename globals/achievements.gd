extends CanvasLayer

var unlocked_achievements := []

signal achievement_unlocked(id: int, title: String, description: String, badge_path: String)

@onready var badge_texture = $Control/achievement_popup_holder/HBoxContainer/MarginContainer/Panel/achievement_badge
@onready var title_label = $Control/achievement_popup_holder/HBoxContainer/MarginContainer2/Panel/achievement_title
@onready var desc_label = $Control/achievement_popup_holder/HBoxContainer/MarginContainer2/Panel/achievement_description
@onready var anim_player: AnimationPlayer = $hud_animations

func _ready():
	hide()

func unlock_achievement(id: int):
	if id not in unlocked_achievements:
		unlocked_achievements.append(id)
		
	var index := id - 1

	if index < 0 or index >= preload("res://scenes/menu/scripts/menu_achievements.gd").ACHIEVEMENTS.size():
		push_error("Invalid achievement ID: %s" % id)
		return

	# Check if already unlocked
	if id in SaveManager.game_save.unlocked_achievements:
		return

	# ===============================
	# ADD TO SAVE (LOCAL)
	# ===============================
	SaveManager.game_save.unlocked_achievements.append(id)
	SaveManager.save_game()

	# ===============================
	# PUSH TO ONLINE SAVE 
	# ===============================
	if SaveManager.current_user_id != 0:
		SaveManager._push_online_save(
		SaveManager.game_save.current_act,
		SaveManager.game_save.current_scene
	)
		print("Achievement pushed online:", id)

	# ===============================
	# SHOW POPUP
	# ===============================
	var achievement_data = preload("res://scenes/menu/scripts/menu_achievements.gd").ACHIEVEMENTS[index]
	_show_popup(achievement_data)

	emit_signal("achievement_unlocked", id, achievement_data.title, achievement_data.description, achievement_data.badge)


func _show_popup(data: Dictionary):
	badge_texture.texture = load(data.badge)
	title_label.text = data.title
	desc_label.text = data.description

	show()
	anim_player.play("popup_in")

	var t = Timer.new()
	t.wait_time = anim_player.get_animation("popup_in").length + 6.0
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(func():
		anim_player.play("popup_out")
		var t2 = Timer.new()
		t2.wait_time = anim_player.get_animation("popup_out").length
		t2.one_shot = true
		t2.autostart = true
		t2.timeout.connect(func():
			hide()
			t2.queue_free()
		)
		add_child(t2)
		t.queue_free()
	)
	add_child(t)
