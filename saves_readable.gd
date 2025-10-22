extends Node

func _ready():
	var src = "user://saves.res"
	var dest = "user://saves_readable.tres"

	if FileAccess.file_exists(src):
		var data = load(src)
		var err = ResourceSaver.save(data, dest)
		if err == OK:
			print("✅ Converted to readable:", dest)
		else:
			print("❌ Error converting:", err)
	else:
		print("⚠️ Walang save file na nakita.")
