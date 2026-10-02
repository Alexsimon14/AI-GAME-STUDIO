# AI GAME STUDIO

AI-assisted Android game studio built around Codex, Godot and a human approval workflow.

## Initial objective
Research the Android game market, select a small first MVP, build it in Godot, test it, release it through Google Play testing tracks, and use telemetry to decide what to improve.

## Start here
1. Open this repository in Codex.
2. Ask Codex to read `AGENTS.md`.
3. Run the first market research prompt from `prompts/01-first-market-research.md`.
4. Review `reports/market/` before allowing concept/GDD work to continue.

## Core stack
- Android
- Godot + GDScript
- Git/GitHub
- Firebase only when needed (Analytics/Crashlytics/Remote Config)
- Backend only when the game actually requires one

## Club Legacy — Phase 0 bootstrap

Project: `games/club-legacy/project.godot`. Import this file in the Godot project manager. The phase records below describe successive deliveries; the current project includes the Phase 5 Vertical Slice.

Validated with **Godot 4.7.2.stable.official.ed1daf0bf** (Windows headless). Compatibility renderer is configured; viewport dimensions are bootstrap placeholders, not a final Android layout decision.

From the repository root, with Godot available as `godot`:

```powershell
godot --headless --path games/club-legacy --editor --quit
godot --headless --path games/club-legacy --script res://tests/run_tests.gd
godot --headless --path games/club-legacy --script res://tests/run_tests.gd -- --force-failure
godot --headless --path games/club-legacy --quit-after 2
```

The normal runner passed 14 checks (exit 0); the intentional failure probe returned 1. Import and headless project startup passed. If Godot is not on PATH, use its full executable path. On Windows, use `Start-Process -Wait -PassThru` when needed to capture the GUI executable's actual exit code; the QA report documents this invocation. Android remains unvalidated; no export was attempted. See [Phase 0 QA report](reports/qa/phase-0-bootstrap.md).

Phase 1 adds in-memory world creation through `scripts/domain/services/world_factory.gd`: 12 fictional clubs, two divisions, 216 players and 217 contracts. The same runner now executes Phase 0 + Phase 1: **88 passed, 0 failed**, with TEST / PLACEHOLDER generation configuration. No gameplay or save system is implemented. See [Phase 1 QA report](reports/qa/phase-1-world-model.md).

Phase 2 adds explicit JSON schema 1 persistence, checksum and redundant A/B snapshots under `user://`. The runner now verifies all three phases: **136 passed, 0 failed**; tests use and clean their own directory. No gameplay or save UI is implemented. See [Phase 2 QA report](reports/qa/phase-2-persistence.md).

Phase 3 adds a deterministic calendar, externally supplied results, derived standings and season completion. Persistence uses schema 2 with a tested schema 1 migration. The runner verifies **322 passed, 0 failed**, preserving the previous 136 checks. No Match Engine or annual division transition is implemented. See [Phase 3 QA report](reports/qa/phase-3-season-competition.md).

Phase 4 adds an independent incremental Match Engine, tactical commands and three substitutions, with active-match checkpoints in save schema 3 and migration from schema 2. The full runner verifies **410 passed, 0 failed**, preserving the previous 322 checks. TEST / PLACEHOLDER batch: 10,000 matches plus 2,000 paired home-advantage comparisons. Run the batch separately with `godot --headless --path games/club-legacy --script res://tests/simulation/run_match_batch.gd`. No match UI, Vertical Slice or Android validation yet. See [Phase 4 QA report](reports/qa/phase-4-match-engine.md).

Phase 5 adds a desktop Vertical Slice: create a manager, choose a club profile, select a lineup, follow an incremental match, receive its result and view updated standings. Open the project and run it with F6 (Main) or F5. Save explicitly with **Salvar**; **Continuar** loads the last saved checkpoint, including a paused active match. Closing without saving loses changes after that checkpoint. Pre-match selections and the detailed result screen are transient; committed fixture scores remain saved. There is no operational economy or annual career transition yet.

The full runner verifies **490 passed, 0 failed** (410 previous checks + 80 new checks); the intentional probe returns exit 1. A graphical smoke rendered nine screens that were inspected, but real mouse/keyboard interaction remains **OWNER CHECK REQUIRED**. Fast slice-only checks: `godot --headless --path games/club-legacy --script res://tests/run_vertical_slice.gd`. This is not the complete MVP; Phase 6 and Android were not started. See [Phase 5 QA report](reports/qa/phase-5-vertical-slice.md).
