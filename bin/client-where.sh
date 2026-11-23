#!/bin/bash
# Status bar: for a terminal attached over ssh, prints where it connects from (" <icon> <machine>").
# Prints nothing for a local terminal. Called as #(client-where.sh #{client_pid}); tmux draws the
# bar per client, so each terminal gets its own answer.
pid=$1
. "${STARBASE_HOME:-$HOME/.tmux-starbase}/bin/lib.sh"
[ -n "$pid" ] || exit 0

# the answer cannot change while the client lives; key the cache on pid + start time (pids are reused)
started=$(ps -o lstart= -p "$pid" | tr -dc '0-9A-Za-z')
CACHE=${TMPDIR:-/tmp}/tmux-client-where-$pid-$started
if [ -f "$CACHE" ]; then cat "$CACHE"; exit 0; fi

# the tmux client inherits SSH_CONNECTION ("<from ip> <port> <to ip> <port>") from the ssh session
ip=$(ps eww -o command= -p "$pid" | tr ' ' '\n' | sed -n 's/^SSH_CONNECTION=//p' | head -1)
if [ -z "$ip" ]; then : > "$CACHE"; exit 0; fi

# with Tailscale the address becomes the machine's name; without it the address is shown
TS=$(tailscale_bin)
name=""
[ -n "$TS" ] && name=$("$TS" status 2>/dev/null | awk -v ip="$ip" '$1 == ip { print $2 }')
printf ' \xef\x83\xac %s' "${name:-$ip}" | tee "$CACHE"
