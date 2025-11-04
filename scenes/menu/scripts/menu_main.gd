extends Control

@onready var continue_game: Button = $options_holder/continue_game
@onready var new_game: Button = $options_holder/new_game
@onready var load_game: Button = $options_holder/load_game
@onready var report_bug: Button = $options_holder/report_bug
@onready var credits: Button = $options_holder/credits
@onready var o_options: Button = $options_holder/options
@onready var exit: Button = $options_holder/exit
@onready var overlayer: Control = $overlayer
@onready var options: VBoxContainer = $options_holder
@onready var logout_button: Button = $logoutButton
@onready var welcome_label: RichTextLabel = $TextureRect/welcome
@onready var welcome_bg: ColorRect = $TextureRect/ColorRect
@onready var exit_confirmation_dialog: ConfirmationDialog = $exitConfirmationDialog
@onready var logout_confirmation_dialog: ConfirmationDialog = $logoutConfirmationDialog
@onready var continue_confirmation_dialog: ConfirmationDialog = $continueConfirmationDialog

var current_choice = 0

func _ready() -> void:
	# Show welcome background only if this is the current scene
	welcome_bg.visible = get_tree().current_scene == self

	SignalBus.online_save_merged.connect(_on_online_save_ready)
	_update_continue_visibility()
	_update_welcome_label()

	if SaveManager.game_save:
		print("finished scenes: " + str(SaveManager.game_save.finished_scenes))
		print("scene choices: " + str(SaveManager.game_save.choices))
		print("Current Karma: " + str(SaveManager.game_save.karma))
		print("Act to continue: " + str(SaveManager.game_save.current_act))
		print("Scene to continue: " + str(SaveManager.game_save.current_scene))
	else:
		print("No local save yet.")

	if SaveManager.has_save():
		continue_game.visible = true
		current_choice = 0
	else:
		current_choice = 1
		continue_game.visible = false

	var options_menu = options.get_children()
	options_menu[current_choice].grab_focus()

	SignalBus.exit_overlay.connect(_exit_overlay)

	for option in options_menu:
		option.mouse_entered.connect(_option_hover.bind(option))

	if not continue_confirmation_dialog.confirmed.is_connected(_start_continue_game):
		continue_confirmation_dialog.confirmed.connect(_start_continue_game)

func _update_welcome_label() -> void:
	var name_text = ""
	if Session.logged_in:
		name_text = Session.username.to_upper()
	else:
		name_text = "GUEST"

	welcome_label.bbcode_enabled = true
	welcome_label.text = "[center]WELCOME,\n%s![/center]" % name_text

func _option_hover(option: Button) -> void:
	current_choice = options.get_children().find(option)
	option.grab_focus()

func _on_continue_game_pressed() -> void:
	if not SaveManager.has_save():
		return
	
	var act = SaveManager.game_save.current_act
	var scene = SaveManager.game_save.current_scene
	continue_confirmation_dialog.dialog_text = "You have previous progress in %s - %s.\nDo you want to continue?" % [act.capitalize(), scene.capitalize()]
	continue_confirmation_dialog.popup_centered()

func _start_continue_game() -> void:
	if BgmManager:
		BgmManager.stop_music()
	SaveManager.load_game()
	var act: String = SaveManager.game_save.current_act
	var scene: String = SaveManager.game_save.current_scene
	SignalBus.next_scene.emit("res://scenes/game/" + act + "/" + scene + "/" + act + "_" + scene + ".tscn")

func _on_new_game_pressed() -> void:
	_option_overlayer("res://scenes/menu/menu_new_game_slots.tscn")

func _on_load_game_pressed() -> void:
	_option_overlayer("res://scenes/menu/menu_load_game_slots.tscn")

func _on_report_bug_pressed() -> void:
	_option_overlayer("res://scenes/menu/menu_report_a_bug.tscn")
	current_choice = options.get_children().find(report_bug)


func _on_credits_pressed() -> void:
	print("credits")
	_option_overlayer("res://scenes/menu/menu_credits.tscn")

	current_choice = options.get_children().find(credits)


func _on_options_pressed() -> void:
	print("options")
	_option_overlayer("res://scenes/menu/menu_game_settings.tscn")
	current_choice = options.get_children().find(o_options)


func _on_exit_pressed() -> void:
	print("exit")
	exit_confirmation_dialog.show();

func _option_overlayer(path: String) -> void:
	# Hide welcome background whenever an overlay is open
	welcome_bg.visible = false
	for child in overlayer.get_children():
		child.queue_free()
	var settings = load(path)
	var settings_instance = settings.instantiate()
	overlayer.add_child(settings_instance)
	overlayer.visible = true

func _exit_overlay() -> void:
	overlayer.visible = false
	options.get_children()[current_choice].grab_focus()

	# Show welcome background again if still on MenuMain scene
	if get_tree().current_scene == self:
		welcome_bg.visible = true

func _on_feedback_pressed() -> void:
	OS.shell_open("https://forms.gle/i6TE17FkpqA7mywk8")

func _on_exit_confirmation_dialog_confirmed() -> void:
	get_tree().quit()

func _on_exit_confirmation_dialog_canceled() -> void:
	# do nothing
	pass # Replace with function body.

func _on_logout_button_pressed() -> void:
	logout_confirmation_dialog.show()


func _on_logout_confirmation_dialog_confirmed() -> void:
	queue_free()
	SignalBus.next_scene.emit("res://scenes/menu/boot_warning.tscn")
	Session.logout_session()


func _on_logout_confirmation_dialog_canceled() -> void:
	# do nothing
	pass # Replace with function body.

func _update_continue_visibility() -> void:
	if SaveManager.has_save():
		continue_game.visible = true
	else:
		continue_game.visible = false

func _on_online_save_ready() -> void:
	print("[MenuMain] Online save merged — refreshing Continue button visibility")
	_update_continue_visibility()
