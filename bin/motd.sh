#!/bin/bash
# Login banner: machine status, tailnet, tmux workspaces and the reminder to run `starbase`.
# Optional; to use it add this to ~/.zshrc, before the prompt is set up:
#   [[ -o interactive && -z $TMUX ]] && ~/.tmux-starbase/bin/motd.sh
# Every probe is optional: a missing
# tool just drops its line.

. "${STARBASE_HOME:-$HOME/.tmux-starbase}/bin/lib.sh"
TMUX_BIN=tmux
TAILSCALE=$(tailscale_bin)

dim=$'\033[38;5;244m'; bold=$'\033[1m'; ok=$'\033[32m'; warn=$'\033[33m'; bad=$'\033[31m'; off=$'\033[0m'

# color <value> <warn-at> <bad-at> -> picks a color for a "higher is worse" number
color() { if [ "$1" -ge "$3" ]; then printf '%s' "$bad"; elif [ "$1" -ge "$2" ]; then printf '%s' "$warn"; else printf '%s' "$ok"; fi; }

up=$(uptime | sed -E 's/.*up ([^,]+(, *[0-9]+:[0-9]+)?),.*/\1/; s/  */ /g')
load=$(sysctl -n vm.loadavg | awk '{print $2}')
cores=$(sysctl -n hw.ncpu)
load_pct=$(awk -v l="$load" -v c="$cores" 'BEGIN{printf "%d", l*100/c}')
mem_free=$(memory_pressure 2>/dev/null | awk -F': ' '/free percentage/{gsub("%","",$2); print $2}')
read -r disk_free disk_used <<EOF
$(df -h /System/Volumes/Data | awk 'NR==2{gsub("%","",$5); print $4, $5}')
EOF

printf '\n  %s%s%s  %s%s%s\n' "$bold" "$(hostname -s)" "$off" "$dim" "$(date '+%a %d %b %H:%M')" "$off"
printf '  %sup%s %s   %sload%s %s%s%s   ' "$dim" "$off" "$up" "$dim" "$off" "$(color "$load_pct" 70 100)" "$load" "$off"
[ -n "$mem_free" ] && printf '%smem%s %s%s%% free%s   ' "$dim" "$off" "$(color $((100 - mem_free)) 80 90)" "$mem_free" "$off"
[ -n "$disk_used" ] && printf '%sdisk%s %s%s free%s' "$dim" "$off" "$(color "$disk_used" 80 90)" "$disk_free" "$off"
printf '\n'

# which tailnet this machine is on decides who can reach it
if [ -x "$TAILSCALE" ]; then
  ts=$("$TAILSCALE" status --json 2>/dev/null | /usr/bin/python3 -c '
import json, sys
d = json.load(sys.stdin)
print(d.get("BackendState", "?"), d.get("CurrentTailnet", {}).get("Name", "?"), (d.get("Self", {}).get("TailscaleIPs") or ["?"])[0])' 2>/dev/null)
  if [ -n "$ts" ]; then
    set -- $ts
    if [ "$1" = Running ]; then printf '  %stailnet%s  %s%s%s · %s\n' "$dim" "$off" "$ok" "$2" "$off" "$3"
    else printf '  %stailnet%s  %s%s%s\n' "$dim" "$off" "$bad" "$1" "$off"; fi
  fi
fi

if "$TMUX_BIN" has-session 2>/dev/null; then
  sessions=$("$TMUX_BIN" list-sessions -F '#{session_name} #{session_windows}')
  n_ws=$(printf '%s\n' "$sessions" | wc -l | tr -d ' ')
  n_tabs=$(printf '%s\n' "$sessions" | awk '{s+=$NF} END{print s}')
  n_claude=$("$TMUX_BIN" list-panes -a -F '#{pane_current_command}' | grep -c '^claude$')
  printf '  %stmux%s     %s workspaces · %s tabs · %s claude\n' "$dim" "$off" "$n_ws" "$n_tabs" "$n_claude"
  printf '           %s%s%s\n' "$dim" "$(printf '%s\n' "$sessions" | awk '{printf "%s%s %s", (NR>1 ? " · " : ""), $1, $NF}')" "$off"
else
  printf '  %stmux%s     %snot running%s\n' "$dim" "$off" "$warn" "$off"
fi

printf '\n  %s→ starbase%s   open the tmux workspaces\n\n' "$bold$ok" "$off"
