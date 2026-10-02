extends RefCounted
## Read-only composition using the approved native components and tokens.
const C = preload("res://ui/game_components.gd")
const T = preload("res://ui/slice_theme.gd")
const Finance = preload("res://scripts/domain/finance/finance_service.gd")
const Money = preload("res://ui/money_formatter.gd")
const NAMES = {"OPENING_BALANCE": "Abertura financeira", "MATCHDAY_REVENUE": "Bilheteria", "WAGES": "Salários", "MAINTENANCE": "Manutenção"}

func build(main: Control, parent: VBoxContainer) -> void:
	var flow = main.session.flow
	var finance = Finance.new()
	var summary: Dictionary = finance.summary(flow.world, flow.club_id())
	C.label(parent, "FINANÇAS", T.TITLE)
	C.label(parent, "Unidades fictícias · salários e manutenção por rodada", T.CAPTION, T.MUTED)
	if summary.is_empty():
		C.empty(parent, "A economia ainda não foi inicializada nesta carreira.")
		return
	var head := C.card(parent, "CAIXA DO CLUBE")
	_metric(head, "Saldo atual", summary.balance, "FinanceBalance", T.DISPLAY)
	if summary.balance < 0: C.label(head, "Saldo negativo. Despesas obrigatórias continuam por rodada.", T.CAPTION, T.DANGER)
	var metrics := GridContainer.new()
	metrics.columns = 2
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics.add_theme_constant_override("h_separation", T.MD)
	metrics.add_theme_constant_override("v_separation", T.SM)
	parent.add_child(metrics)
	_metric(C.card(metrics), "Receitas da temporada", summary.income, "FinanceIncome")
	_metric(C.card(metrics), "Despesas da temporada", summary.expenses, "FinanceExpenses")
	_metric(C.card(metrics), "Resultado líquido", summary.net, "FinanceNet")
	_metric(C.card(metrics), "Folha por rodada", summary.payroll, "FinancePayroll")
	var composition := C.card(parent, "COMPOSIÇÃO DA TEMPORADA")
	for category in ["MATCHDAY_REVENUE", "WAGES", "MAINTENANCE"]:
		var amount: int = summary.categories.get(category, 0)
		C.label(composition, NAMES[category] + "  " + Money.format_amount(amount), T.BODY, T.DANGER if amount < 0 else T.TEXT)
	C.label(composition, "Abertura não é receita da temporada. Sem premiação nesta fase.", T.CAPTION, T.MUTED)
	var ledger := C.card(parent, "MOVIMENTAÇÕES RECENTES")
	ledger.name = "FinanceLedger"
	var entries: Array = finance.ledger(flow.world, flow.club_id())
	# Display latest entries; retained full history stays canonical in the world.
	for index in range(entries.size() - 1, maxi(-1, entries.size() - 13), -1):
		var entry: Dictionary = entries[index]
		var row := VBoxContainer.new()
		row.set_meta("financial_entry", entry.duplicate(true))
		ledger.add_child(row)
		var period: String = "Abertura" if entry.category == "OPENING_BALANCE" else "Rodada %d" % entry.round_number
		C.label(row, NAMES[entry.category] + " · " + period, T.CAPTION, T.MUTED)
		var direction: String = "SAÍDA" if entry.amount < 0 else "ENTRADA"
		C.label(row, direction + "  " + Money.format_amount(entry.amount), T.BODY, T.DANGER if entry.amount < 0 else T.SUCCESS)

func _metric(parent: Node, title: String, amount: int, node_name: String, font_size: int = T.SECTION) -> void:
	C.label(parent, title, T.CAPTION, T.MUTED)
	var value := C.label(parent, Money.format_amount(amount), font_size, T.DANGER if amount < 0 else T.GOLD)
	value.name = node_name
