#!/bin/bash
# Opens a menu on the client given as $1: the machines online in the current tailnet (information
# only) and one entry per other Tailscale account of this machine to switch to it.
# A terminal attached from a machine that is not on the chosen tailnet loses its connection, so a
# switch always asks for confirmation first.
# ("--" before the rows: the non-selectable ones start with "-" and would be read as flags)
. "${STARBASE_HOME:-$HOME/.tmux-starbase}/bin/lib.sh"
TS=$(tailscale_bin)
client=$1
[ -n "$TS" ] || { tmux display-message -c "$client" " Tailscale is not installed "; exit 0; }
# resolved here: tmux would try to expand a ${...} left inside the menu command and reject it
cache=${TMPDIR:-/tmp}/tmux-starbase-sysstat

items=()
# tailscale status: <ip> <name> <user> <os> <state...>; a leading "-" makes a menu row non-selectable
while read -r _ name _ os state; do
  [[ -z $name || $state == *offline* ]] && continue
  items+=("-  $name  ($os)" "" "")
done < <("$TS" status 2>/dev/null | grep -E '^[0-9]')
online=$(( ${#items[@]} / 3 ))

switches=()
current="?"
while IFS=$'\t' read -r id tailnet account; do
  if [[ $account == *'*' ]]; then
    current=$tailnet
  else
    switches+=("Switch to $tailnet ..." "" "confirm-before -p \"Switch this machine to $tailnet? Terminals coming from another tailnet disconnect (y/n)\" \"run-shell '$TS switch $id; rm -f $cache'\"")
  fi
done < <("$TS" switch --list | tail -n +2 | awk -F'  +' '{ print $1 "\t" $2 "\t" $3 }')

tmux display-menu -c "$client" -T "#[align=centre] $current · $online online " -x C -y C -- \
  "${items[@]}" "" "${switches[@]}"
