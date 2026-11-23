# Your workspaces. Read by the `starbase` command; plain bash.
#
#   ws <name> <color>            a workspace (a tmux session) and its color in the status bar
#   tab <name> <dir> [command]   a tab in it (a tmux window); the command is typed, not run
#
# The colors always apply. The tabs are only a starter layout: they are created when tmux starts
# with no saved layout (the very first run). After that, whatever you had open is what comes back.

ws Home "#196F3D"
tab shell "$HOME"

# ws Backend "#7D6608"
# tab api    "$HOME/Code/api"    "claude"
# tab worker "$HOME/Code/worker"
#
# ws Frontend "#1A5276"
# tab web "$HOME/Code/web" "claude"
