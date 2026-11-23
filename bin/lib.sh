# Shared helpers, sourced by the other scripts. Optional tools are looked up here so the rest of the
# code can simply skip a feature when its tool is missing.

STARBASE_HOME=${STARBASE_HOME:-$HOME/.tmux-starbase}
# scripts started by launchd or by tmux may get a bare PATH; make sure both Homebrew prefixes are on it
# (appended, so whatever the user put first still wins)
PATH=$PATH:/opt/homebrew/bin:/usr/local/bin

# tailscale_bin -> the Tailscale CLI: the standalone one, or the one inside the macOS app; empty if none
tailscale_bin() {
  command -v tailscale 2>/dev/null && return
  local app=/Applications/Tailscale.app/Contents/MacOS/Tailscale
  [ -x "$app" ] && printf '%s\n' "$app"
}

# docker_bin -> the docker CLI from PATH (Docker Desktop, Colima...) or from OrbStack; empty if none
docker_bin() {
  command -v docker 2>/dev/null && return
  [ -x "$HOME/.orbstack/bin/docker" ] && printf '%s\n' "$HOME/.orbstack/bin/docker"
}
