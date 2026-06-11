#!/usr/bin/env bash
# Kiln installer (macOS / Linux) — downloads the prebuilt binary, NO source, NO build.
#
#   curl -fsSL https://raw.githubusercontent.com/Stevemech/Kiln/main/scripts/install.sh | bash
#   KILN_REPO=owner/repo bash scripts/install.sh           # pick the public release repo
#   KILN_REPO=owner/repo KILN_VERSION=v0.1.0 bash …         # pin a version (default: latest)
#   bash scripts/install.sh --uninstall                     # remove kiln + the PATH line we added
#
# Windows: use  powershell -ExecutionPolicy Bypass -File scripts/install.ps1.
#
# Kiln drives the `opencode` CLI at runtime (not bundled) and needs a model BACKEND you run
# yourself — LM Studio (recommended) or Ollama. This installer handles opencode and points you
# at a backend.

set -euo pipefail

# --- config (override via env) ---------------------------------------------------------------
# REPLACE "Stevemech/Kiln" with your PUBLIC release repo, or pass KILN_REPO=owner/repo.
REPO="${KILN_REPO:-Stevemech/Kiln}"
VERSION="${KILN_VERSION:-latest}"           # a tag like v0.1.0, or "latest"
BIN_DIR="${KILN_BIN_DIR:-$HOME/.local/bin}"
# Optional: override the download base entirely (self-hosted mirror / testing). When unset we
# build the GitHub Releases URL from REPO + VERSION.
DOWNLOAD_BASE="${KILN_DOWNLOAD_BASE:-}"
NAME="kiln"

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

profile_file() {
  case "${SHELL:-}" in
    */zsh)  echo "$HOME/.zshrc" ;;
    */bash) [ -f "$HOME/.bashrc" ] && echo "$HOME/.bashrc" || echo "$HOME/.profile" ;;
    *)      echo "$HOME/.profile" ;;
  esac
}
PATH_TAG="# added by Kiln installer"

# --- uninstall -------------------------------------------------------------------------------
if [ "${1:-}" = "--uninstall" ]; then
  say "Uninstalling Kiln…"
  rm -f "$BIN_DIR/$NAME" && ok "Removed $BIN_DIR/$NAME" || true
  prof="$(profile_file)"
  if [ -f "$prof" ] && grep -q "$PATH_TAG" "$prof"; then
    # `|| true`: grep -v exits 1 when NOTHING remains (profile was only our line) — under
    # `set -e` that would abort and leave the line + a stale .tmp. Always write + move.
    grep -v "$PATH_TAG" "$prof" > "$prof.kiln.tmp" || true
    mv "$prof.kiln.tmp" "$prof"
    ok "Removed the PATH line from $prof"
  fi
  ok "Done. (opencode + your model backend were left installed.)"
  exit 0
fi

# --- detect platform / arch → asset name -----------------------------------------------------
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS" in
  Darwin) PLAT="macos" ;;
  Linux)  PLAT="linux" ;;
  MINGW*|MSYS*|CYGWIN*) die "Windows detected — run: powershell -ExecutionPolicy Bypass -File scripts/install.ps1" ;;
  *) die "Unsupported OS: $OS (supported: macOS, Linux)." ;;
esac
case "$ARCH" in
  x86_64|amd64)  A="x64" ;;
  arm64|aarch64) A="arm64" ;;
  *) die "Unsupported architecture: $ARCH (supported: x64, arm64)." ;;
esac
ASSET="kiln-${PLAT}-${A}"
say "Platform: ${PLAT} ${A} → ${ASSET}"

# --- resolve download base -------------------------------------------------------------------
# Newest published tag INCLUDING prereleases. GitHub's /releases/latest/ skips prereleases, but
# alpha/beta tags ARE prereleases, so we resolve the newest via the API (no jq — grep the first
# "tag_name"). Works unauthenticated for a public repo.
resolve_latest_tag() {
  curl -fsSL "https://api.github.com/repos/${REPO}/releases?per_page=1" 2>/dev/null \
    | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
}
if [ -z "$DOWNLOAD_BASE" ]; then
  [ "$REPO" = "OWNER/kiln" ] && die "Set the release repo: KILN_REPO=owner/repo bash install.sh (or edit REPO at the top)."
  if [ "$VERSION" = "latest" ]; then
    TAG="$(resolve_latest_tag || true)"
    [ -n "$TAG" ] || die "Couldn't resolve the latest release from ${REPO}. Pin one: KILN_VERSION=vX.Y.Z bash install.sh"
    say "Latest release: ${TAG}"
    DOWNLOAD_BASE="https://github.com/${REPO}/releases/download/${TAG}"
  else
    DOWNLOAD_BASE="https://github.com/${REPO}/releases/download/${VERSION}"
  fi
fi

# --- download binary + checksums -------------------------------------------------------------
have curl || die "curl is required."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
say "Downloading ${ASSET} from ${DOWNLOAD_BASE}…"
curl -fSL "${DOWNLOAD_BASE}/${ASSET}" -o "$TMP/$ASSET" || die "Download failed. Check KILN_REPO/KILN_VERSION and that the release has a ${ASSET} asset."
curl -fsSL "${DOWNLOAD_BASE}/SHA256SUMS" -o "$TMP/SHA256SUMS" || die "Couldn't fetch SHA256SUMS from the release."

# --- verify checksum -------------------------------------------------------------------------
EXPECTED="$(awk -v a="$ASSET" '$2==a {print $1}' "$TMP/SHA256SUMS")"
[ -n "$EXPECTED" ] || die "No checksum for ${ASSET} in SHA256SUMS."
if have sha256sum; then ACTUAL="$(sha256sum "$TMP/$ASSET" | awk '{print $1}')"
elif have shasum;   then ACTUAL="$(shasum -a 256 "$TMP/$ASSET" | awk '{print $1}')"
else die "Need sha256sum or shasum to verify the download."; fi
[ "$EXPECTED" = "$ACTUAL" ] || die "Checksum mismatch for ${ASSET} (expected ${EXPECTED}, got ${ACTUAL}). Aborting."
ok "Checksum verified."

# --- install onto PATH -----------------------------------------------------------------------
mkdir -p "$BIN_DIR"
mv "$TMP/$ASSET" "$BIN_DIR/$NAME"
chmod +x "$BIN_DIR/$NAME"
# macOS: clear the download quarantine so Gatekeeper doesn't block the unsigned binary.
[ "$PLAT" = "macos" ] && xattr -d com.apple.quarantine "$BIN_DIR/$NAME" 2>/dev/null || true
ok "Installed to $BIN_DIR/$NAME"

if ! have "$NAME" || [ "$(command -v "$NAME")" != "$BIN_DIR/$NAME" ]; then
  case ":$PATH:" in
    *":$BIN_DIR:"*) : ;; # already on PATH (a different kiln?); leave the profile alone
    *)
      prof="$(profile_file)"
      if ! grep -qs "$PATH_TAG" "$prof" 2>/dev/null; then
        printf '\nexport PATH="%s:$PATH"  %s\n' "$BIN_DIR" "$PATH_TAG" >> "$prof"
        say "Added $BIN_DIR to PATH in $prof"
      fi
      warn "Open a NEW shell (or: source $prof) so 'kiln' is found."
      ;;
  esac
fi

# --- opencode (runtime dependency — NOT bundled) ---------------------------------------------
if have opencode; then
  ok "opencode found: $(opencode --version 2>/dev/null || echo '?')"
else
  say "Installing opencode (the agent Kiln drives; https://opencode.ai)…"
  curl -fsSL https://opencode.ai/install | bash || true
  export PATH="$HOME/.opencode/bin:$PATH"
  if have opencode; then ok "opencode installed."
  else warn "Couldn't install opencode automatically. Install it (https://opencode.ai/docs) so 'opencode --version' works, then you're set — Kiln spawns it at runtime."; fi
fi

# --- done ------------------------------------------------------------------------------------
echo
ok "Kiln installed — run \`kiln\`."
echo
say "One thing left: a model backend (not installed by Kiln)."
echo "    • LM Studio  (recommended)  https://lmstudio.ai   — serves the model's full context, zero config"
echo "    • Ollama                    https://ollama.com    — set OLLAMA_CONTEXT_LENGTH=16384 for agentic use"
echo "    Then pull/download a tool-capable model (e.g. Qwen2.5-Coder 7B)."
echo
say "Next:  kiln doctor   (check setup)   ·   kiln   (start)   ·   bash install.sh --uninstall   (remove)"
