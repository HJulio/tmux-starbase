#!/bin/bash
# tmux-resurrect post-save-layout hook: appends the conversation id of each pane that has one
# (set by claude/tmux-hook.py) to the snapshot file given as $1. `starbase` reads these lines on restore;
# tmux-resurrect ignores line types it does not know.
TAB=$'\t'
tmux list-panes -a \
  -F "claude${TAB}#{session_name}${TAB}#{window_index}${TAB}#{pane_index}${TAB}#{@claude_session}" |
  awk -F'\t' '$5 != ""' >> "$1"
