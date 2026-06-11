# Kiln installer (Windows) — downloads the prebuilt binary, NO source, NO build.
#
#   irm https://raw.githubusercontent.com/Stevemech/Kiln/main/scripts/install.ps1 | iex
#   $env:KILN_REPO="owner/repo"; powershell -ExecutionPolicy Bypass -File scripts\install.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Uninstall
#
# Set KILN_REPO to your PUBLIC release repo (or edit $Repo below). KILN_VERSION pins a tag.
# Kiln drives the `opencode` CLI at runtime (not bundled) + needs a model BACKEND you run
# yourself — LM Studio (recommended) or Ollama. macOS/Linux: use scripts/install.sh.

param([switch]$Uninstall)

$ErrorActionPreference = "Stop"
# Windows PowerShell 5.1 (the documented host) defaults to TLS 1.0 — github.com requires TLS 1.2+,
# so downloads fail without this. And IWR's progress bar throttles big downloads to a crawl on
# 5.1, so silence it.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"
function Say($m)  { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "OK  $m" -ForegroundColor Green }
function Warn($m) { Write-Host "!   $m" -ForegroundColor Yellow }
function Die($m)  { Write-Host "x   $m" -ForegroundColor Red; exit 1 }
function Have($c) { return [bool](Get-Command $c -ErrorAction SilentlyContinue) }

# --- config (override via env) ---------------------------------------------------------------
$Repo    = if ($env:KILN_REPO) { $env:KILN_REPO } else { "Stevemech/Kiln" }   # PUBLIC release repo
$Version = if ($env:KILN_VERSION) { $env:KILN_VERSION } else { "latest" }
$BinDir  = if ($env:KILN_BIN_DIR) { $env:KILN_BIN_DIR } else { Join-Path $env:USERPROFILE ".kiln\bin" }
$DownloadBase = $env:KILN_DOWNLOAD_BASE  # optional self-hosted/test override
$Exe = Join-Path $BinDir "kiln.exe"

if ($Uninstall) {
  Say "Uninstalling Kiln..."
  if (Test-Path $Exe) { Remove-Item $Exe -Force; Ok "Removed $Exe" }
  $envKey = "HKCU:\Environment"
  $rawPath = (Get-Item $envKey).GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
  if ($rawPath -and (($rawPath -split ';') -contains $BinDir)) {
    $newPath = (($rawPath -split ';') | Where-Object { $_ -ne $BinDir -and $_ -ne "" }) -join ';'
    Set-ItemProperty -Path $envKey -Name Path -Value $newPath -Type ExpandString
    Ok "Removed $BinDir from your user PATH."
  }
  Ok "Done. (opencode + your model backend were left installed.)"
  return
}

# --- detect arch → asset ---------------------------------------------------------------------
# Only a Windows x64 binary is published; arm64 Windows runs it via emulation.
$Asset = "kiln-windows-x64.exe"
Say "Platform: Windows ($env:PROCESSOR_ARCHITECTURE) -> $Asset"

# --- resolve download base -------------------------------------------------------------------
if (-not $DownloadBase) {
  if ($Repo -eq "OWNER/kiln") { Die "Set the release repo: `$env:KILN_REPO='owner/repo' (or edit `$Repo at the top)." }
  if ($Version -eq "latest") {
    # Newest published tag INCLUDING prereleases (the API list — unlike /releases/latest, which
    # skips prereleases, and our alpha/beta tags ARE prereleases).
    try { $tag = @(Invoke-RestMethod "https://api.github.com/repos/$Repo/releases?per_page=1" -UseBasicParsing)[0].tag_name } catch { $tag = $null }
    if (-not $tag) { Die "Couldn't resolve the latest release from $Repo. Pin one: `$env:KILN_VERSION='vX.Y.Z'" }
    Say "Latest release: $tag"
    $DownloadBase = "https://github.com/$Repo/releases/download/$tag"
  } else {
    $DownloadBase = "https://github.com/$Repo/releases/download/$Version"
  }
}

# --- download + verify -----------------------------------------------------------------------
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("kiln-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $Tmp | Out-Null
try {
  Say "Downloading $Asset from $DownloadBase ..."
  try {
    Invoke-WebRequest -Uri "$DownloadBase/$Asset" -OutFile "$Tmp\$Asset" -UseBasicParsing
    Invoke-WebRequest -Uri "$DownloadBase/SHA256SUMS" -OutFile "$Tmp\SHA256SUMS" -UseBasicParsing
  } catch { Die "Download failed. Check KILN_REPO/KILN_VERSION and that the release has a $Asset asset." }

  $line = (Get-Content "$Tmp\SHA256SUMS" | Where-Object { $_ -match "\s$([regex]::Escape($Asset))$" } | Select-Object -First 1)
  if (-not $line) { Die "No checksum for $Asset in SHA256SUMS." }
  $expected = ($line -split '\s+')[0].ToLower()
  $actual = (Get-FileHash "$Tmp\$Asset" -Algorithm SHA256).Hash.ToLower()
  if ($expected -ne $actual) { Die "Checksum mismatch for $Asset (expected $expected, got $actual). Aborting." }
  Ok "Checksum verified."

  New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
  Move-Item "$Tmp\$Asset" $Exe -Force
  Ok "Installed to $Exe"
} finally {
  Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# --- PATH ------------------------------------------------------------------------------------
# Read/write the User PATH via the registry, preserving %VAR% references (REG_EXPAND_SZ).
# [Environment]::SetEnvironmentVariable would rewrite it as a plain REG_SZ, permanently flattening
# any %USERPROFILE%/%ProgramFiles% etc. the user has in their PATH.
$envKey = "HKCU:\Environment"
$rawPath = (Get-Item $envKey).GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
if (($rawPath -split ';') -notcontains $BinDir) {
  $newPath = if ($rawPath) { "$rawPath;$BinDir" } else { $BinDir }  # no leading ';' when empty
  Set-ItemProperty -Path $envKey -Name Path -Value $newPath -Type ExpandString
  Say "Added $BinDir to your user PATH."
  Warn "Open a NEW terminal so 'kiln' is found."
} else {
  Ok "$BinDir is already on your PATH."
}

# --- opencode (runtime dependency — NOT bundled) ---------------------------------------------
if (Have opencode) {
  Ok "opencode found."
} else {
  Say "Installing opencode (the agent Kiln drives; https://opencode.ai)..."
  try { Invoke-RestMethod https://opencode.ai/install.ps1 | Invoke-Expression } catch { Warn "Automatic opencode install failed." }
  # Refresh this session's PATH so a freshly-installed opencode is visible (avoids a false warning).
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
  if (Have opencode) { Ok "opencode installed." }
  else { Warn "Install opencode manually (https://opencode.ai/docs) so 'opencode --version' works — Kiln spawns it at runtime." }
}

Write-Host ""
Ok "Kiln installed - run: kiln"
Write-Host ""
Say "One thing left: a model backend (not installed by Kiln)."
Write-Host "    LM Studio (recommended)  https://lmstudio.ai   - serves the model's full context, zero config"
Write-Host "    Ollama                   https://ollama.com    - set OLLAMA_CONTEXT_LENGTH=16384 for agentic use"
Write-Host "    Then pull/download a tool-capable model (e.g. Qwen3 4B Instruct — run /models inside Kiln for picks that fit your GPU)."
Write-Host ""
Say "Next:  kiln doctor   (check setup)   then   kiln   (start)"
Write-Host "       powershell -File scripts\install.ps1 -Uninstall   to remove"
