#!/bin/bash
# Jumps to the first tab, in any workspace, where an agent is waiting (its bell flag is set).
target=$(tmux list-windows -a -f '#{window_bell_flag}' -F '#{session_id}:#{window_id}' | head -1)
if [ -n "$target" ]; then tmux switch-client -t "$target"; else tmux display-message " No agent is waiting "; fi
