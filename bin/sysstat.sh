#!/bin/bash
# Status bar segment: CPU load, CPU temperature, RAM in use, Docker state with the number of running
# containers, and the current tailnet. Called from status-right as #(...). Prints tmux style codes.
# Every part is optional: without macmon, docker or tailscale that part is simply left out.
. "${STARBASE_HOME:-$HOME/.tmux-starbase}/bin/lib.sh"

# tmux re-runs this on every status redraw, up to once a second; reuse the last output for 10 s
CACHE=${TMPDIR:-/tmp}/tmux-starbase-sysstat
if [ -f "$CACHE" ] && [ $(( $(date +%s) - $(stat -f %m "$CACHE") )) -lt 10 ]; then cat "$CACHE"; exit 0; fi
exec > >(tee "$CACHE")

sep=""

# one macmon sample takes about a second; fine because tmux does not wait for it
if command -v macmon >/dev/null; then
  macmon pipe -s 1 2>/dev/null | /usr/bin/python3 -c '
import json, sys

d = json.loads(sys.stdin.readline())
text, warn, bad = "#dfe5ee", "#f9e2af", "#ff6b6b"


def color(value, warn_at, bad_at):
    return bad if value >= bad_at else warn if value >= warn_at else text


# share of time the cores were busy (the *_scaled/usage_pct fields also weigh in the clock speed and read much lower)
cpu = round(d["cpu_active_ratio"] * 100)
temp = round(d["temp"]["cpu_temp_avg"])
used = d["memory"]["ram_usage"] / 2**30
total = d["memory"]["ram_total"] / 2**30
# fixed-width numbers, so the segments to the left do not shift when a value gains a digit
print(
    f"#[fg=#fab387]\U000f0ee0 #[fg={color(cpu, 60, 85)}]{cpu:>3}%"
    f"  #[fg=#f5c2e7]\U000f050f #[fg={color(temp, 70, 90)}]{temp:>2}°"
    f"  #[fg=#89b4fa]\U000f035b #[fg={color(used * 100 / total, 80, 92)}]{used:>2.0f}/{total:.0f}G",
    end="",
)
' 2>/dev/null && sep="  "
fi

# Docker: "on" plus the number of running containers, or "off" when the daemon does not answer.
# The range makes it clickable (see MouseDown1Status in starbase.conf); it must end with range=right.
DOCKER=$(docker_bin)
if [ -n "$DOCKER" ]; then
  if ids=$("$DOCKER" ps -q 2>/dev/null); then
    printf '%s#[range=user|docker]#[fg=#9fef00]\xf3\xb0\xa1\xa8 on #[fg=#dfe5ee]%s#[range=right]' "$sep" "$(printf '%s' "$ids" | grep -c .)"
  else
    printf '%s#[fg=#7f8ea3]\xf3\xb0\xa1\xa8 off' "$sep"
  fi
  sep="  "
fi

# which tailnet this machine is on
TAILSCALE=$(tailscale_bin)
if [ -n "$TAILSCALE" ]; then
  tailnet=$("$TAILSCALE" status --json 2>/dev/null | /usr/bin/python3 -c '
import json, sys
d = json.load(sys.stdin)
print(d["CurrentTailnet"]["Name"] if d.get("BackendState") == "Running" else "off")' 2>/dev/null)
  [ -n "$tailnet" ] && printf '%s#[range=user|tailnet]#[fg=#cba6f7]\xf3\xb0\x96\x82 #[fg=#dfe5ee]%s#[range=right]' "$sep" "$tailnet"
fi
