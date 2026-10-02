extends RefCounted

static func format_amount(value: int) -> String:
	# String handling also supports int64 minimum without overflowing abs().
	var digits: String = str(value).trim_prefix("-")
	var grouped: String = ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0: grouped += "."
		grouped += digits[index]
	return ("-¤ " if value < 0 else "¤ ") + grouped
