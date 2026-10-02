extends RefCounted
## Original presentation catalog. Names never determine domain IDs or relationships.
const CATALOG = {
	"Aurora de Neral": ["AN", "b98b37", "171f2b"],
	"Vale de Tervan": ["VT", "438d72", "dee8de"],
	"Porto de Luren": ["PL", "527ca7", "e2e7ef"],
	"Estrela de Soval": ["ES", "b5ac75", "343e61"],
	"Monte de Ardel": ["MA", "8e678c", "efe0cc"],
	"União de Veldra": ["UV", "b55c62", "e8e1d7"],
	"Riacho de Belven": ["RB", "4d929b", "dcecee"],
	"Lago de Orven": ["LO", "657eaa", "d6dfed"],
	"Pedra de Ceral": ["PC", "a0795f", "ece3d8"],
	"Campos de Darel": ["CD", "8b9b56", "e4e9d1"],
	"Vila de Erel": ["VE", "9b7184", "eee0e5"],
	"Horizonte de Farel": ["HF", "b28455", "e5d9c9"]
}
static func get_identity(club) -> Dictionary:
	var entry: Array = CATALOG.get(club.name, [])
	if entry.is_empty():
		var initials: String = ""
		for word in club.name.split(" ", false):
			if word not in ["de", "do", "da"]: initials += word.left(1)
		return {"abbreviation": initials.left(3).to_upper(), "primary": Color.from_hsv(float(club.id.sha256_text().left(4).hex_to_int() % 360) / 360.0, 0.4, 0.65), "secondary": Color("e0e5ec")}
	return {"abbreviation": entry[0], "primary": Color(entry[1]), "secondary": Color(entry[2])}
