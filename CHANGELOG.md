# Changelog

All notable changes to Kiln are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/), and Kiln aims for
[Semantic Versioning](https://semver.org/).

## [0.1.0-alpha.1] — 2026-06-08 (binaries refreshed 2026-06-11)

> The alpha.1 release assets were rebuilt on 2026-06-11 with everything below — same tag,
> substantially more Kiln.

### Added (2026-06-11 refresh)
- **The autonomy mode dial** — plan / ask / act / auto, switched LIVE mid-session with
  `Shift+Tab` or `/mode` (+ `/plan` `/ask` `/act` `/auto`); cockpit badge; replaces the
  per-tool approval settings (which silently never worked against opencode 1.16 — fixed).
- **`/models`** — hardware-aware model discovery from a hand-verified catalog (exact pull
  tags, task tags, honest cautions; broken-for-agents families excluded with reasons).
- **`/verify`** — the tool-call preflight: proves a model emits STRUCTURED tool calls on
  your own GPU; verdicts persist and badge the pickers ("✓ tools verified" / "⚠ tools fail live").
- **`/duel`** — one prompt, two local models, side-by-side answers with honest numbers.
- **`/backend`** — live backend switching (also `b` from `/model` and `/settings`); the
  conversation reattaches.
- **Preheat** — Kiln warms the model's prompt cache at launch so the first real prompt
  skips the cold prefill (`KILN_PREHEAT=0` to disable).
- **Cloud-savings odometer** — the session total shows ≈$ of metered-API spend avoided.
- **Tiered onboarding** — an experience question; beginners get a warm, hardware-aware
  guide (what your machine can run, honest expectations, per-OS install steps).
- **In-Kiln LM Studio downloads** — `/pull` now works on LM Studio too (catalog search,
  recommended quant, byte progress). Models pulled mid-session auto-register on `/model`.
- **Slash-command mini-picker** — `↑/↓` pick a suggestion, Enter runs the highlight.

### Fixed (2026-06-11 refresh)
- Honest telemetry: cockpit rates/meters now accumulate across a turn's steps (no more
  cache-replay "26k tok/s prefill" fictions or mid-turn meter dips).
- Honest VRAM math: fit badges credit the models a load will displace; capacity-based
  guidance in onboarding.
- The slash-hint lag / right-edge flicker / frame-overflow paint corruption on short
  terminals; overlay row-merging; a shutdown that could leave a zombie process.

First public alpha. Kiln is a local-first terminal coding agent: it drives opencode against a
model on **your** machine (LM Studio, Ollama, or any OpenAI-compatible endpoint), with a live
full-screen cockpit. Offline by default.

### Added
- **Full-screen TUI** — cockpit (tokens/sec, context meter, live model state), parameter rail
  (temperature / top-p / context, per-model), transcript with in-app scroll, and an ember-fox
  mascot that reacts to what the model is doing.
- **Multi-backend control** behind one interface: LM Studio (recommended), Ollama, and a
  generic OpenAI-compatible endpoint, with capability-gated UI (greys out what a backend can't
  do instead of faking it).
- **Onboarding** that auto-detects backends + GPU/VRAM and recommends the model your hardware
  can actually run; steers toward LM Studio.
- **Sessions** — resume / rename / search / export to Markdown; per-project memory.
- **Model management** — `/pull` with VRAM-aware recommendations, favorites/recent, fit
  estimates.
- **Permissions & web** — offline by default; per-tool edit/shell approval; a web-access
  toggle; and a strict, provable **airgap** mode with a persistent network badge.
- **Model routing** (opt-in, guard-heavy) — never routes a tool turn to a no-tools model;
  co-residence-gated.
- **Speed** — lean-tool prefill trim, `kiln bench`, optional LSP-off.
- **CLI** — `kiln`, `kiln --plain`, `kiln doctor`, `kiln bench`, `kiln --version`,
  `kiln onboard`; mouse-wheel scrolling that preserves native text selection.
- **First-run welcome** from the creator + a revivable `/tour`.
- **One-command installer** — `scripts/install.sh` (macOS/Linux) and `scripts/install.ps1`
  (Windows).

### Fixed
- **Ollama context meter** — diagnosed that Ollama's OpenAI `/v1` endpoint serves every request
  at `OLLAMA_CONTEXT_LENGTH` (4096 if unset) and silently truncates longer prompts, and that
  opencode wasn't requesting streaming token usage. Kiln now passes `includeUsage`, advertises
  only the context Ollama will really serve, and `kiln doctor` warns when `OLLAMA_CONTEXT_LENGTH`
  is unset/too small.

### Known rough edges (alpha)
- **Windows is unverified** end-to-end — the installer and launcher are written to be
  cross-platform, but they haven't been run through on Windows yet.
- **Ollama** needs `OLLAMA_CONTEXT_LENGTH=16384` (or more) set on the server for real agentic
  use; LM Studio needs no such knob (hence the recommendation).
- Vision input is gated by what the backend's OpenAI endpoint forwards; the affordance exists
  but image pass-through depends on the backend.

<!-- Release links: add once a remote exists, e.g.
[0.1.0-alpha.1]: https://github.com/<owner>/kiln/releases/tag/v0.1.0-alpha.1 -->

