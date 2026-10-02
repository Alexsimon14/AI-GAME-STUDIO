extends RefCounted
## Event value, sequenced by the simulator; no RNG or clock here.
static func record(index: int, minute: int, kind: String, club_id: String = "", player_id: String = "", context: Dictionary = {}) -> Dictionary:
	return {"id": index, "minute": minute, "kind": kind, "club_id": club_id, "player_id": player_id, "context": context.duplicate(true)}
