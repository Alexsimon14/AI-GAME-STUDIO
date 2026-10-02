extends RefCounted

var id: String = ""
var club_id: String = ""
var season_id: String = ""
var round_number: int = 0
var category: String = ""
var amount: int = 0 # Positive income/opening; negative expense.
var operation_key: String = ""
var description_key: String = ""
var context: Dictionary = {}

func descriptor() -> Dictionary:
	return {"club_id": club_id, "season_id": season_id, "round_number": round_number,
		"category": category, "amount": amount, "operation_key": operation_key,
		"description_key": description_key, "context": context.duplicate(true)}

func projection() -> Dictionary:
	var value := descriptor()
	value["id"] = id
	return value
