#!/bin/bash
# tmux-starbase installer (macOS). Idempotent: safe to re-run after a `git pull`.
#
#   git clone https://github.com/HJulio/tmux-starbase ~/.tmux-starbase
#   ~/.tmux-starbase/install.sh
#
# Options:
#   --autostart   also start tmux with your workspaces at login (launchd agent)
#   --no-brew     do not install packages (you take care of the dependencies)
#   --no-claude   do not register the Claude Code hooks
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
STARBASE_HOME=$HOME/.tmux-starbase
PLUGINS=$STARBASE_HOME/plugins
CONFIG=$HOME/.config/starbase
# plugin commits this setup is built and tested against
PANE_TREE_REF=ae50f232cd022e2bd3805aacc4370a34ad634d40
TREEMUX_REF=50dbddb5ef7ff9d2381d51477d7d53e64d3819fd
RESURRECT_REF=cff343cf9e81983d3da0c8562b01616f12e8d548
CONTINUUM_REF=0698e8f4b17d6454c71bf5212895ec055c578da0

AUTOSTART=0; BREW=1; CLAUDE=1
for arg in "$@"; do
  case $arg in
    --autostart) AUTOSTART=1 ;;
    --no-brew) BREW=0 ;;
    --no-claude) CLAUDE=0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

[ "$(uname)" = Darwin ] || { echo "tmux-starbase is built for macOS. See docs/linux.md for what a port needs." >&2; exit 1; }
PATH=/opt/homebrew/bin:/usr/local/bin:$PATH
command -v brew >/dev/null || { echo "Homebrew is required: https://brew.sh" >&2; exit 1; }
# where the starbase and preview commands are linked; override to keep them out of Homebrew's bin
BIN_DIR=${STARBASE_BIN_DIR:-$(brew --prefix)/bin}

# the config refers to ~/.tmux-starbase; a checkout elsewhere is reached through a symlink
if [ "$REPO" != "$STARBASE_HOME" ] && [ ! -e "$STARBASE_HOME" ]; then
  ln -s "$REPO" "$STARBASE_HOME"
  echo "linked $STARBASE_HOME -> $REPO"
fi
[ "$(cd "$STARBASE_HOME" && pwd -P)" = "$(cd "$REPO" && pwd -P)" ] ||
  { echo "$STARBASE_HOME exists and is not this checkout; move it away or install from there." >&2; exit 1; }

# plugin <git url> <dir> <commit> -> clone once, pinned
plugin() {
  if [ ! -d "$PLUGINS/$2" ]; then
    git clone -q "$1" "$PLUGINS/$2"
    git -C "$PLUGINS/$2" checkout -q "$3"
    echo "cloned $2 at ${3:0:7}"
  fi
}

if [ "$BREW" = 1 ]; then
  echo "== packages"
  # required. bash 5: tmux-pane-tree needs bash 4+; neovim: treemux draws the file tree with it
  brew install tmux bash neovim fzf
  # optional extras: editor for files picked in the tree, git popup, status bar stats
  brew install fresh-editor lazygit macmon || echo "some optional packages failed to install; their features stay off"
fi
/usr/bin/python3 -c 'import pynvim' 2>/dev/null || /usr/bin/python3 -m pip install --user -q pynvim

echo "== tmux plugins"
mkdir -p "$PLUGINS"
plugin https://github.com/sandudorogan/tmux-pane-tree tmux-pane-tree "$PANE_TREE_REF"
plugin https://github.com/kiyoon/treemux treemux "$TREEMUX_REF"
plugin https://github.com/tmux-plugins/tmux-resurrect tmux-resurrect "$RESURRECT_REF"
plugin https://github.com/tmux-plugins/tmux-continuum tmux-continuum "$CONTINUUM_REF"
# look of the session tree: folder and terminal icons, muted tree lines, bold workspace names
if git -C "$PLUGINS/tmux-pane-tree" apply --check "$REPO/patches/tmux-pane-tree-look.patch" 2>/dev/null; then
  git -C "$PLUGINS/tmux-pane-tree" apply "$REPO/patches/tmux-pane-tree-look.patch"
  echo "patched tmux-pane-tree"
fi

echo "== configuration"
mkdir -p "$CONFIG" "$HOME/.config/nvim-starbase" "$HOME/.local/state/starbase/snapshots"
ln -sfn "$STARBASE_HOME/nvim/init.lua" "$HOME/.config/nvim-starbase/init.lua"
for f in workspaces.sh local.conf; do
  [ -e "$CONFIG/$f" ] || { cp "$REPO/examples/$f" "$CONFIG/$f"; echo "created $CONFIG/$f"; }
done
LINE='source-file ~/.tmux-starbase/tmux/starbase.conf'
if ! grep -qsF "$LINE" "$HOME/.tmux.conf"; then
  [ -e "$HOME/.tmux.conf" ] && [ ! -e "$HOME/.tmux.conf.pre-starbase" ] && cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.pre-starbase"
  printf '\n# tmux-starbase (remove this line to turn it off)\n%s\n' "$LINE" >> "$HOME/.tmux.conf"
  echo "added starbase to ~/.tmux.conf"
fi
mkdir -p "$BIN_DIR"
ln -sfn "$STARBASE_HOME/bin/starbase" "$BIN_DIR/starbase"
ln -sfn "$STARBASE_HOME/bin/preview" "$BIN_DIR/preview"
echo "linked starbase and preview into $BIN_DIR"

echo "== file tree plugins (the first run downloads them)"
NVIM_APPNAME=nvim-starbase nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true

if [ "$CLAUDE" = 1 ] && { [ -d "$HOME/.claude" ] || command -v claude >/dev/null; }; then
  echo "== Claude Code hooks (tree badges, notifications, conversation ids)"
  /usr/bin/python3 "$REPO/claude/install-claude-hooks.py"
fi

if [ "$AUTOSTART" = 1 ]; then
  echo "== login item"
  PLIST=$HOME/Library/LaunchAgents/com.tmux-starbase.plist
  mkdir -p "$(dirname "$PLIST")"
  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.tmux-starbase</string>
  <!-- At login: start tmux and restore the workspaces. Without a terminal the command does not attach. -->
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$STARBASE_HOME/bin/starbase</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>StandardErrorPath</key><string>/tmp/tmux-starbase-launchagent.log</string>
</dict>
</plist>
EOF
  echo "installed $PLIST (takes effect at the next login)"
fi

tmux source-file "$HOME/.tmux.conf" 2>/dev/null && echo "reloaded the running tmux server" || true

cat <<'EOF'

Done. Run:  starbase

Worth doing next (see README.md):
  - use a Nerd Font in your terminal, or the bar and tree icons show as boxes
  - describe your workspaces in ~/.config/starbase/workspaces.sh
  - on the machines you connect from, add the snippets in client/
EOF
