extends Node

# ─────────────────────────────────────────────
#  Leaderboard.gd  —  AutoLoad singleton
#  Uses Nakama's official Godot SDK.
#
#  SETUP:
#  1. Install Nakama server via Docker (one-liner):
#       docker run --name nakama -p 7350:7350 -p 7351:7351 -p 7349:7349 \
#         heroiclabs/nakama --name burst_bound
#     Or use Heroic Cloud (managed, free dev tier):
#       https://heroiclabs.com/heroic-cloud/
#
#  2. Download the Godot Nakama SDK:
#       https://github.com/heroiclabs/nakama-godot/releases
#     Unzip and drop the addons/nakama folder into res://addons/nakama
#
#  3. Enable plugin:
#       Project > Project Settings > Plugins > Nakama > Enable
#
#  4. Fill in the constants below.
# ─────────────────────────────────────────────

const SERVER_HOST := "127.0.0.1"  # your server IP / heroic cloud URL
const SERVER_PORT := 7350
const SERVER_KEY  := "defaultkey" # matches your server config
const USE_SSL     := false

const LB_SCORE := "burst_bound_score"  # higher = better  (operator: BEST)
const LB_TIME  := "burst_bound_time"   # lower  = better  (operator: BEST, store negative)
const PAGE_SIZE := 10

signal scores_loaded(entries: Array)
signal score_submitted(ok: bool)
signal authenticated(ok: bool)

var _client  : NakamaClient
var _session : NakamaSession


func _ready() -> void:
	_client = Nakama.create_client(
		SERVER_KEY, SERVER_HOST, SERVER_PORT,
		"http" if not USE_SSL else "https"
	)


# ── authentication ────────────────────────────
# Uses device ID so the player never needs to register.
# Call this once at app start (e.g. from _ready in main_menu.gd).

func authenticate() -> void:
	var device_id : String = OS.get_unique_id()
	if device_id.is_empty():
		device_id = "player_" + str(randi())

	var session = await _client.authenticate_device_async(
		device_id, true, SaveData.player_name
	)

	if session.is_exception():
		push_error("Nakama auth failed: " + str(session.get_exception()))
		authenticated.emit(false)
		return

	_session = session
	authenticated.emit(true)


# ── fetch leaderboard ─────────────────────────

func fetch_top_scores(sort_by: String = "score") -> void:
	if not _check_session():
		return

	var lb_id := LB_TIME if sort_by == "time_secs" else LB_SCORE

	var result = await _client.list_leaderboard_records_async(
		_session, lb_id, [], PAGE_SIZE
	)

	if result.is_exception():
		push_error("Leaderboard fetch failed: " + str(result.get_exception()))
		scores_loaded.emit([])
		return

	var entries : Array = []
	for record in result.records:
		var meta : Dictionary = _parse_meta(record.metadata)
		var display_score : int
		var display_time  : int

		if lb_id == LB_TIME:
			# stored as negative to invert Nakama's descending sort
			display_time  = -int(record.score)
			display_score = meta.get("score", 0)
		else:
			display_score = int(record.score)
			display_time  = meta.get("time_secs", 0)

		entries.append({
			"rank":      int(record.rank),
			"player":    record.username,
			"score":     display_score,
			"time_secs": display_time,
			"rating":    meta.get("rating", "-"),
		})

	scores_loaded.emit(entries)


# ── submit score ──────────────────────────────

func submit_score(score: int, rating: String, time_secs: int) -> void:
	if not _check_session():
		return

	# Score board: higher is better, Nakama keeps personal best automatically.
	var r1 = await _client.write_leaderboard_record_async(
		_session, LB_SCORE, score, 0,
		JSON.stringify({"rating": rating, "time_secs": time_secs})
	)

	# Time board: store as negative so lower time = higher (better) rank.
	var r2 = await _client.write_leaderboard_record_async(
		_session, LB_TIME, -time_secs, 0,
		JSON.stringify({"rating": rating, "score": score})
	)

	var ok := not r1.is_exception() and not r2.is_exception()
	if not ok:
		push_error("Submit failed: " + str(r1.get_exception()))
	score_submitted.emit(ok)


# ── utilities ─────────────────────────────────

func format_time(secs: int) -> String:
	return "%d:%02d" % [secs / 60, secs % 60]


func _check_session() -> bool:
	if _session == null or _session.is_expired():
		push_warning("Nakama: no active session. Call Leaderboard.authenticate() first.")
		return false
	return true


func _parse_meta(raw: String) -> Dictionary:
	if raw.is_empty():
		return {}
	var parsed : Variant = JSON.parse_string(raw)
	return parsed if parsed is Dictionary else {}
