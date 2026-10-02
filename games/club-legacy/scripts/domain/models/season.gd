extends RefCounted

var id: String = ""
var number: int = 1
var status: String = "READY"
var current_round: int = 1
var members: Dictionary = {} # Frozen league IDs -> club IDs.
var tiebreak_order: Dictionary = {} # Preseason draw; never changed by reads.
var round_states: Dictionary = {} # String round number -> READY/RESOLVING/COMMITTED.
var operations: Dictionary = {} # Operation key -> immutable command descriptor.
