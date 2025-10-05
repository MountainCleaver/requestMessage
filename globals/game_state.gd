extends Node

# === SCENE STATE FLAGS ===
var current_act: String = "act_1"
var current_scene: String = "scene_4"

# === CHAT FLAGS ===
var checked_sched := false
var chat_objectives_added := false
var wendy_reply_shown := false
var mira_reply_shown := false
var wendy_opened := false
var mira_opened := false
var gc_opened := false
var unknown_sender_opened := false
var set1_objective_done := false
var objective8_added := false
var has_gone_home := false

# === CHAT HISTORY (we link this to ChatManager) ===
func save_chat_state():
	GameStateChatData = ChatManager.history.duplicate(true)

func load_chat_state():
	if GameStateChatData:
		ChatManager.history = GameStateChatData.duplicate(true)

# Backup variable for deep copy
var GameStateChatData = {}
