# CHAT GUIDE ATA

extends Label

# PRELOAD DIALOGUE
const TEST_DIALOGUE = preload("res://chat_test.dialogue")

# FLAGS
var wendy_opened: bool = false
var wendy_reply_shown: bool = false

# OBJECTIVES
var scene_objectives = [
	{"ID": 1, "text": "OPEN WENDY CHAT"}
]

func _ready() -> void:
	# DAPAT LAGI TO NILALAGAY SA PINAKAUNAHAN KASI SIYA UNG NAGLOLOAD NG PREVIOUS CHAT SA PREVIOUS SCENES
	GameState.load_game()
	
	# LALABAS OBJECTIVE AND DIALOGUE SA START
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	DialogueManager.show_dialogue_balloon(TEST_DIALOGUE, "start")
	
	# SIGNAL BUS
	SignalBus.chat_opened.connect(_on_chat_opened)
	SignalBus.chat_message_sent.connect(_on_chat_message_sent)


func _on_chat_opened(chat_name: String) -> void:
	if chat_name == "wendy" and not wendy_opened:
		wendy_opened = true
		# KAPAG PINAKITA WENDY CHAT MAGCHECHECK NA RIN OBJECTIVE NA NAOPEN NA
		ObjectiveManager.complete_objective(scene_objectives[0]["ID"])
		DialogueManager.show_dialogue_balloon(TEST_DIALOGUE, "first_chat_ni_wendy")

func _on_chat_message_sent(chat_name: String) -> void:
	if chat_name == "wendy" and not wendy_reply_shown:
		wendy_reply_shown = true
		# DITO LALABAS KUNG ANO IREREPLY MO KAY WENDY
		# PERO NEED MO MUNA CLICK YUNG TYPE MESSAGE SA UI NG PHONE CONVO
		DialogueManager.show_dialogue_balloon(TEST_DIALOGUE, "choice_ni_danilo")

# ADD ETO IF SCENE DONE NA
	GameState.save_game()
