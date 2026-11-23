#!/bin/bash
# Puts the side panels of the window given as $1 back to their configured width.
# tmux scales every pane when the terminal changes size, and hands a closed pane's space to its
# neighbour; without this the trees get squeezed on a smaller screen and drift wider over time.
window=$1
tree=$(tmux show -gqv @tmux_pane_tree_width)
files=$(tmux show -gqv @treemux-tree-width)

tmux list-panes -t "$window" -F '#{pane_id} #{pane_width} #{pane_current_command} #{pane_title}' 2>/dev/null |
  while read -r id width command title; do
    if [ "$title" = Sidebar ]; then
      want=${tree:-25}
    elif [ "$command" = nvim ] && [ -n "$(tmux show -gqv "@-treemux-is-treemux-$id")" ]; then
      want=${files:-40}
    else
      continue
    fi
    [ "$width" = "$want" ] || tmux resize-pane -t "$id" -x "$want"
  done
