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

Project: `games/club-legacy/project.godot`. Import this file in the Godot project manager. The Main scene contains only ScreenHost and DialogLayer; there is no gameplay yet.

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
