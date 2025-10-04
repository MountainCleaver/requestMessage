extends Node

# Global storage for all chat histories
var history := {
	"wendy": [],
	"mira": [],
	"group_chat": [],
	"unknown_sender": []
}

# Save message to history
func add_message(chat_name: String, sender: String, text: String) -> void:
	if not history.has(chat_name):
		history[chat_name] = []
	history[chat_name].append({"sender": sender, "text": text})

# Get saved history
func get_history(chat_name: String) -> Array:
	if not history.has(chat_name):
		return []
	return history[chat_name]


func send_chat(chat_name: String, sender: String, text: String) -> void:
	SignalBus.chat_message_received.emit(chat_name, sender, text)
