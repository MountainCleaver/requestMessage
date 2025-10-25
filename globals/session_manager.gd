extends Node
class_name SessionManager

const SESSION_PATH: String = "user://session.cfg"
const SECRET_KEY: String = "ToSaveFaceHowLowCanYouGoTalkALotOfGameAndYetYouDontKnowStaticOnTheWayMakeUsAllSayWoahThePeopleUpTopPushThePeopleDownLowGetDownAndObeyEveryWord"

var username: String = ""
var user_ID: int = 0
var logged_in: bool = false

signal session_loaded

func _ready() -> void:
	load_session()

# ----------------------------------------------------------------
# Save session to file with signature
# ----------------------------------------------------------------
func save_session(_username: String, _user_ID: int) -> void:
	await get_tree().process_frame

	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		print("[SessionManager] SaveManager will load data after session is saved.")
	else:
		print("Warning: SaveManager not ready during save_session.")

	username = _username
	user_ID = _user_ID

	var sig: String = _generate_signature(username, user_ID)

	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("session", "username", username)
	cfg.set_value("session", "user_id", user_ID)
	cfg.set_value("session", "sig", sig)

	var err: int = cfg.save(SESSION_PATH)
	if err != OK:
		push_error("SessionManager: Failed saving session: %s" % str(err))
		logged_in = false
		return

	logged_in = true
	print("SessionManager: Session saved successfully.")
	emit_signal("session_loaded")



# ----------------------------------------------------------------
# Load and validate session (ignore if tampered or invalid)
# ----------------------------------------------------------------
func load_session() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var load_result: int = cfg.load(SESSION_PATH)
	if load_result != OK:
		logged_in = false
		return

	var u: String = str(cfg.get_value("session", "username", ""))
	var id_val: int = int(cfg.get_value("session", "user_id", 0))
	var sig: String = str(cfg.get_value("session", "sig", ""))

	# sanity checks
	if u.is_empty() or sig.is_empty():
		logged_in = false
		return

	# verify signature
	var expected_sig: String = _generate_signature(u, id_val)
	if sig != expected_sig:
		push_warning("SessionManager: Signature mismatch — possible tampering detected.")
		logged_in = false
		return

	# restore session
	username = u
	user_ID = id_val
	logged_in = true
	print("SessionManager: Session loaded. Welcome back, %s" % username)
	emit_signal("session_loaded")


# ----------------------------------------------------------------
# Logout and clear local session
# ----------------------------------------------------------------
func logout_session() -> void:
	username = ""
	user_ID = 0
	logged_in = false

	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		print("[SessionManager] Not resetting SaveManager — next login will load its own save.")
	else:
		print("Warning: SaveManager not ready during logout.")

	if FileAccess.file_exists(SESSION_PATH):
		var file: FileAccess = FileAccess.open(SESSION_PATH, FileAccess.WRITE)
		if file:
			file.store_string("")
			file.close()
			print("SessionManager: Session file cleared.")
		else:
			push_warning("SessionManager: Failed to clear session file.")
	else:
		print("SessionManager: No session file found to clear.")




# ----------------------------------------------------------------
# Generate SHA-256 signature to detect file tampering
# ----------------------------------------------------------------
func _generate_signature(_username: String, _user_id: int) -> String:
	var combo: String = SECRET_KEY + _username + str(_user_id)
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(combo.to_utf8_buffer())
	var digest: PackedByteArray = ctx.finish()
	return digest.hex_encode()


# ----------------------------------------------------------------
# Get current user info (returns empty dictionary if not logged in)
# ----------------------------------------------------------------
func get_user_info() -> Dictionary:
	if not logged_in:
		print("not logged in")
		return {}
	print("username: " + str(username) + "||" + "user id : " + str(user_ID))
	return {
		"username": username,
		"user_id": user_ID
	}


# ----------------------------------------------------------------
# Check login state
# ----------------------------------------------------------------
func is_logged_in() -> bool:
	return logged_in
