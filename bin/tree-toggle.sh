#!/bin/bash
# Toggles the session tree and, when turning it on, opens it in every tab right away.
# The plugin on its own adds the tree to a tab the first time you enter it, which resizes the
# working pane and makes whatever runs there (Claude) redraw on every first visit.
S=$HOME/.tmux-starbase/plugins/tmux-pane-tree/scripts/features/sidebar

"$S/toggle-sidebar.sh"
[ "$(tmux show -gqv @tmux_sidebar_enabled)" = 1 ] || exit 0
tmux list-windows -a -F '#{window_id}' | while read -r window; do
  "$S/ensure-sidebar-pane.sh" "" "$window"
done
