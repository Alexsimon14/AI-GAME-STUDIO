extends RefCounted

var id: String = ""
var kind: String = "" # athlete or employment
var subject_id: String = ""
var club_id: String = ""
var active: bool = true
var end_season: int = 1
var salary: int = 0 # Athlete salary per round; no manager economy.
