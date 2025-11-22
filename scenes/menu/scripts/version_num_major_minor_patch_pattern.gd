extends Label

const LIVE_PATCH_URL := "https://requestmessage-admin.onrender.com/api/get_live_patch.php"

static var cached_version: String = ""
static var fetched: bool = false

func _ready():
	if cached_version != "":
		text = "Version %s" % cached_version
	else:
		text = ""
		if not fetched:
			fetched = true
			fetch_live_version()

func fetch_live_version():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	http.request(LIVE_PATCH_URL)

func _on_request_completed(result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	if result == OK and response_code == 200:
		var json_parser = JSON.new()
		if json_parser.parse(body.get_string_from_utf8()) == OK:
			var data = json_parser.get_data()
			cached_version = data.get("version", "unknown")
			text = "Version %s" % cached_version
