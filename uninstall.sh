#!/bin/bash
# Turns tmux-starbase off and removes what install.sh put outside the checkout. Your workspaces file,
# local.conf and layout snapshots are kept, and so are the packages Homebrew installed.
set -u
PATH=/opt/homebrew/bin:/usr/local/bin:$PATH
BIN_DIR=${STARBASE_BIN_DIR:-$(brew --prefix 2>/dev/null)/bin}

if [ -f "$HOME/.tmux.conf" ]; then
  # drop the source line and the comment above it
  grep -vF -e 'source-file ~/.tmux-starbase/tmux/starbase.conf' -e '# tmux-starbase (remove this line to turn it off)' \
    "$HOME/.tmux.conf" > "$HOME/.tmux.conf.tmp" && mv "$HOME/.tmux.conf.tmp" "$HOME/.tmux.conf"
  echo "removed starbase from ~/.tmux.conf"
fi
for link in "$BIN_DIR/starbase" "$BIN_DIR/preview" "$HOME/.config/nvim-starbase/init.lua"; do
  [ -L "$link" ] && rm "$link" && echo "removed $link"
done
rm -f "$HOME/Library/LaunchAgents/com.tmux-starbase.plist"

# Claude Code hooks: remove every entry that points into ~/.tmux-starbase
if [ -f "$HOME/.claude/settings.json" ]; then
  /usr/bin/python3 - <<'PY'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p))
marker = os.path.expanduser("~/.tmux-starbase/")
removed = 0
for event, groups in list(s.get("hooks", {}).items()):
    for g in groups:
        before = len(g.get("hooks", []))
        g["hooks"] = [h for h in g.get("hooks", []) if not h.get("command", "").startswith(marker)]
        removed += before - len(g["hooks"])
    s["hooks"][event] = [g for g in groups if g.get("hooks")]
    if not s["hooks"][event]:
        del s["hooks"][event]
if removed:
    json.dump(s, open(p, "w"), indent=2)
print(f"claude hooks: {removed} removed")
PY
fi

cat <<'EOF'

tmux-starbase is off. A running tmux server keeps the old settings until it is restarted.
Left in place, delete them if you do not want them:
  ~/.tmux-starbase   ~/.config/starbase   ~/.local/state/starbase   ~/.local/share/nvim-starbase
EOF
