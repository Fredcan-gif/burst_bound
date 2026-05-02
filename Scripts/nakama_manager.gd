extends Node

var client: NakamaClient
var session: NakamaSession

const SERVER_HOST = "127.0.0.1"
const SERVER_PORT = 7350
const SERVER_KEY = "defaultkey"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	client = Nakama.create_client(SERVER_KEY, SERVER_HOST, SERVER_PORT, "http")
	await authenticate()

func authenticate() -> void:
	var device_id = OS.get_unique_id()
	var username = "Player_" + OS.get_unique_id().substr(0, 6)
	session = await client.authenticate_device_async(device_id, username, true)
	if session.is_exception():
		print("Auth failed: ", session.get_exception())
	else:
		print("Authenticated as: ", session.user_id)

func submit_score(score: int) -> void:
	if not session:
		return
	var result = await client.list_leaderboard_records_async(
	session, "my_game_scores", [], null, 3
	)
	if result.is_exception():
		print("Score submit failed: ", result.get_exception())
	else:
		print("Score submitted: ", score)

func fetch_leaderboard() -> Array:
	if not session:
		return []
	var result = await client.list_leaderboard_records_async(
		session, "my_game_scores", [], null, 10
	)
	if result.is_exception():
		print("Fetch failed: ", result.get_exception())
		return []
	return result.records
