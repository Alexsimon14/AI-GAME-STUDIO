# AI GAME STUDIO — Codex Instructions

## Mission
Build a reusable AI-assisted mobile game studio focused exclusively on Android.

## Product constraints
- Platform: Android only until the owner explicitly changes this.
- Engine: Godot.
- Primary game language: GDScript.
- Prefer offline/single-player MVPs and low infrastructure cost.
- Do not copy protected game assets, names, characters, levels, or source code.
- Human approval is required before starting a new game, changing monetization strategy, spending money, creating production credentials, or publishing to Google Play.

## Studio roles
Use the role files in `agents/` when a task clearly belongs to one specialty:
- `market-researcher.md` — Android market and competitor research.
- `product-manager.md` — concepts, GDD, scope, economy and roadmap.
- `game-architect.md` — Godot architecture and technical plans.
- `game-developer.md` — implementation.
- `qa-engineer.md` — tests, bugs, regression and Android validation.
- `game-analyst.md` — telemetry, retention, funnels and economy analysis.

For independent investigations, use parallel agents when available. Do not let multiple agents edit the same files concurrently.

## Workflow gates
1. Research -> `reports/market/`
2. Concepts -> human selection
3. GDD -> `docs/gdd/` -> human approval
4. Architecture/plan -> `docs/architecture/`
5. Implementation -> `games/<game-slug>/`
6. QA -> `reports/qa/`
7. Android test build
8. Human approval before any store release
9. Analytics -> `reports/analytics/`

## Engineering rules
- Inspect existing files before editing.
- Keep changes small and reviewable.
- Never commit secrets, signing keys, service-account JSON, passwords or tokens.
- Use `.env.example` for documented environment variables.
- Run relevant tests after changes and report what was/was not verified.
- Do not claim a build works unless it was actually built/tested.
- Never publish to production automatically.
- Prefer reusable systems under `shared/` only after a pattern is proven in a game.

## Planning
For work expected to span multiple components or take substantial implementation, create/update a plan under `docs/plans/` before editing code.
