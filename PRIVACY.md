# Privacy

**Kiln collects nothing and sends nothing.** It has no telemetry, no analytics, no
crash reporting, no "check for updates," no account, and no servers of its own. Nothing
about you, your code, or your conversations ever leaves your machine because of Kiln.

This isn't a policy choice layered on top — it's how Kiln is built. The model runs locally
(LM Studio / Ollama / your own endpoint), the agent (opencode) runs locally, and your
sessions are stored locally under `~/.kiln/`. You can run Kiln on a fully air-gapped machine.

## The only network activity is what *you* turn on

Kiln is **offline by default.** The few things that can touch the network are explicit,
opt-in, and visible:

| Action | Reaches the network? | How to control it |
| --- | --- | --- |
| Normal coding (read/edit/write/shell) | No | — |
| Web tools (`webfetch` / `websearch`) | Only when **`/web on`** | `/web off` (the default) |
| Downloading a model (`/pull`) | Yes, to your backend's registry | Don't pull; download models yourself |
| `kiln --version` | No (it never phones home) | — |

The cockpit shows a persistent **NET** badge — `OFFLINE`, `ONLINE`, or `AIRGAP` — so you
always know your posture at a glance.

## Airgap mode

For sensitive code, turn on **strict airgap** (`/settings → g`, or `--plain /airgap on`).
It hard-disables all web tools regardless of any other setting, so you can *prove* nothing
egresses. The badge reads `⊘ AIRGAP`.

## Third parties

The model backend you choose (LM Studio, Ollama, a custom endpoint) and the opencode CLI are
separate programs with their own behavior — but in Kiln's default configuration they run
locally and are not asked to send your data anywhere. If you point Kiln at a *remote*
OpenAI-compatible endpoint, your prompts go to that endpoint, by your choice.

Questions: stevemech2020@gmail.com
