extends RefCounted
const Tests = preload("res://tests/unit/match_engine_tests.gd")
const Simulator = preload("res://scripts/domain/match/match_simulator.gd")

func run(check: Callable) -> void:
	var sim = Simulator.new()
	var started: int = Time.get_ticks_msec()
	var memory_start: int = OS.get_static_memory_usage()
	var memory_samples: Array = [memory_start]
	var aggregate: Dictionary = _empty()
	var scenarios: Dictionary = {}
	var all_coherent: bool = true
	# Exactly 10,000, fixed seeds and no wall-clock-derived sporting decisions.
	var cases := [["equivalent", 2000, 60, 60, 100, "EQUILIBRADA"], ["home_stronger", 1500, 85, 40, 100, "EQUILIBRADA"], ["away_stronger", 1500, 40, 85, 100, "EQUILIBRADA"], ["small_vs_elite", 1000, 37, 77, 100, "EQUILIBRADA"], ["reduced_condition", 1000, 60, 60, 25, "EQUILIBRADA"], ["offensive", 1500, 60, 60, 100, "OFENSIVA"], ["cautious", 1500, 60, 60, 100, "CAUTELOSA"]]
	for scenario in cases:
		var totals: Dictionary = _empty()
		for n in range(scenario[1]):
			var data: Dictionary = Tests.data(scenario[2], scenario[3], n)
			for p in data.home.players.values(): p.condition = float(scenario[4])
			data.home.tactic = scenario[5]
			var run: Dictionary = sim.simulate(Tests.input_from(data))
			if not run.errors.is_empty():
				all_coherent = false
				continue
			var result: Dictionary = run.result.snapshot()
			all_coherent = all_coherent and Tests.coherent(result)
			_record(totals, result)
			_record(aggregate, result)
		scenarios[scenario[0]] = totals
		memory_samples.append(OS.get_static_memory_usage())
	var elapsed: int = Time.get_ticks_msec() - started
	print("PHASE4_BATCH ", JSON.stringify({"engine": "1", "config": "phase-4-test-v1", "seeds": "0..scenario_count-1", "count": aggregate.count, "duration_ms": elapsed, "static_memory_start": memory_start, "static_memory_samples": memory_samples, "aggregate": aggregate, "scenarios": scenarios}, "", true))
	check.call(aggregate.count == 10000 and all_coherent, "10,000 matches: no invalid events/authors/stats or simulation errors")
	check.call(aggregate.home_wins > 0 and aggregate.away_wins > 0 and aggregate.draws > 0 and aggregate.zero_zero < aggregate.count and aggregate.max_total < 25, "Batch detects no degenerate result distribution")
	check.call(scenarios.home_stronger.home_wins > scenarios.equivalent.home_wins * 0.75 and scenarios.home_stronger.home_wins > scenarios.home_stronger.away_wins and scenarios.home_stronger.away_wins > 0, "Stronger home side tends to win; upsets remain")
	check.call(scenarios.away_stronger.away_wins > scenarios.away_stronger.home_wins and scenarios.away_stronger.home_wins > 0, "Stronger visitors tend to win; home upsets remain")
	check.call(scenarios.small_vs_elite.away_wins > scenarios.small_vs_elite.home_wins and scenarios.small_vs_elite.draws > 0 and scenarios.small_vs_elite.home_wins > 0, "Small vs elite retains draws and underdog wins")
	check.call(float(scenarios.reduced_condition.home_chances) / 1000.0 < float(scenarios.equivalent.home_chances) / 2000.0, "Reduced condition hurts chance creation statistically")
	check.call(float(scenarios.offensive.home_chances) / 1500.0 > float(scenarios.equivalent.home_chances) / 2000.0 and float(scenarios.offensive.away_chances) / 1500.0 > float(scenarios.equivalent.away_chances) / 2000.0, "Offensive tactic raises own creation and opponent opportunities")
	check.call(float(scenarios.cautious.home_chances) / 1500.0 < float(scenarios.equivalent.home_chances) / 2000.0 and float(scenarios.cautious.away_chances) / 1500.0 < float(scenarios.equivalent.away_chances) / 2000.0, "Cautious tactic lowers own creation and opponent opportunities")
	# Paired comparison: same seeds, teams and config except the initiative parameter.
	var neutral: Dictionary = _empty()
	var advantage: Dictionary = _empty()
	for n in range(1000):
		for enabled in [false, true]:
			var snapshot: Dictionary = Tests.data(60, 60, n + 20000)
			if not enabled: snapshot.config.home_initiative = 0.0
			_record(advantage if enabled else neutral, sim.simulate(Tests.input_from(snapshot)).result.snapshot())
	print("PHASE4_HOME_PAIRED ", JSON.stringify({"count_per_group": 1000, "neutral": neutral, "advantage": advantage}, "", true))
	check.call(advantage.home_ticks > neutral.home_ticks and advantage.home_wins < 650 and advantage.away_wins > 0, "Configurable small home advantage increases initiative without invincibility")
	check.call(memory_samples.back() - memory_start < 32 * 1024 * 1024, "Batch releases match states/results; static memory growth below diagnostic 32 MiB")

func _empty() -> Dictionary:
	return {"count": 0, "home_goals": 0, "away_goals": 0, "home_wins": 0, "draws": 0, "away_wins": 0, "zero_zero": 0, "many_goals_7_plus": 0, "max_total": 0, "max_score": "", "scores": {}, "home_chances": 0, "away_chances": 0, "home_ticks": 0}

func _record(totals: Dictionary, result: Dictionary) -> void:
	var h: int = result.stats.home.goals
	var a: int = result.stats.away.goals
	totals.count += 1
	totals.home_goals += h
	totals.away_goals += a
	totals.home_chances += result.stats.home.chances
	totals.away_chances += result.stats.away.chances
	totals.home_ticks += result.stats.home.possession_ticks
	if h > a: totals.home_wins += 1
	elif h < a: totals.away_wins += 1
	else: totals.draws += 1
	if h + a == 0: totals.zero_zero += 1
	if h + a >= 7: totals.many_goals_7_plus += 1
	var score: String = str(h) + "x" + str(a)
	totals.scores[score] = totals.scores.get(score, 0) + 1
	if h + a > totals.max_total:
		totals.max_total = h + a
		totals.max_score = score
