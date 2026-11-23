#!/bin/bash
# Runs in a tmux popup: fuzzy-pick any tab of any workspace and jump to it.
T=tmux
TAB=$'\t'

target=$($T list-windows -a -F "=#{session_name}:#{window_index}${TAB}#{session_name} / #{window_name}${TAB}#{b:pane_current_path}" |
  fzf --delimiter="$TAB" --with-nth=2,3 --reverse --prompt='tab> ' | cut -f1)
[ -n "$target" ] && $T switch-client -t "$target"
