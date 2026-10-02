extends RefCounted

var config_snapshot: Dictionary = {}
var season_id: String = ""
var baseline_committed_round: int = 0
var processed_rounds: Dictionary = {}
var entries: Dictionary = {} # Persistent ID -> FinancialEntry; canonical money authority.
