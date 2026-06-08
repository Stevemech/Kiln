# Changelog

All notable changes to Kiln are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/), and Kiln aims for
[Semantic Versioning](https://semver.org/).

## [0.1.0-alpha.1] — 2026-06-08

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

