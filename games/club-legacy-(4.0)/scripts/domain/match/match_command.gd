extends RefCounted
## Boundary is the already completed minute; ordered commands affect future minutes.
var id: String = ""
var minute: int = 0
var side: String = "home"
var kind: String = "TACTIC"
var payload: Dictionary = {}

func snapshot() -> Dictionary:
	return {"id": id, "minute": minute, "side": side, "kind": kind, "payload": payload.duplicate(true)}
