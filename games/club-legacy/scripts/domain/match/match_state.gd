extends RefCounted
## Mutable only within the simulator. Detached from the career aggregate.
var input: Dictionary = {}
var minute: int = 0
var phase: String = "FIRST_HALF"
var teams: Dictionary = {}
var stats: Dictionary = {}
var events: Array = []
var commands: Array = []
var rng := RandomNumberGenerator.new()

func view() -> Dictionary:
	return {"minute": minute, "phase": phase, "teams": teams.duplicate(true), "stats": stats.duplicate(true), "events": events.duplicate(true), "commands": commands.duplicate(true)}
