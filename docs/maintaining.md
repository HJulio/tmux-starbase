# Maintaining tmux-starbase

Notes for whoever changes this setup, human or coding agent.

## Never test on your real tmux server

A starbase server holds long-running sessions. Try every change in a sandbox with its own home
directory and its own tmux socket, then reload the real server.

```bash
SB=$(mktemp -d)
export HOME=$SB/home TMUX_TMPDIR=$SB/tmp STARBASE_BIN_DIR=$SB/bin
mkdir -p $HOME $TMUX_TMPDIR
cp -R ~/path/to/checkout $HOME/.tmux-starbase
$HOME/.tmux-starbase/install.sh --no-brew        # everything lands under $SB
PATH=$SB/bin:$PATH starbase </dev/null           # starts the sandboxed server without attaching
tmux show-messages | grep -iE "error|invalid|syntax" | grep -v "@tmux_"     # config errors
# ... exercise the change with plain `tmux ...` commands: they talk to the sandbox ...
tmux kill-server
```

- `TMUX_TMPDIR` is what keeps you off the real server. Without it, `tmux` talks to the default
  socket even when `HOME` points elsewhere.
- The `@tmux_pane_tree_*` / `@tmux_sidebar_*` "invalid option" lines in `show-messages` are the
  session tree probing unset options. They are noise.
- What is seen on screen (colors, icons, popups) cannot be checked from a script. Attach and look.
- Icons in the bar and the trees are Nerd Font code points. Write them from a script as escapes
  (`""`), not by pasting, so an encoding slip cannot corrupt them. Reading the bar back with
  `tmux show` needs a UTF-8 locale, or every icon comes out as an underscore.

## Things that are easy to break

- **Clickable areas in the bar** are `#[range=user|name]` spans handled by `MouseDown1Status`. A
  span must end with `#[range=right]`, not `#[norange]`, or the rest of the right side stops
  opening the menu.
- **Menu commands are parsed by tmux**, which expands `${...}` itself: resolve shell variables in
  the script before building the command. Rows starting with `-` (non-selectable) need `--` before
  them in `display-menu`.
- **Two hooks at index `[250]`** hand the focus back to the working pane when you arrive at a tab
  and redraw the trees. Without them the tree marker freezes after clicking in the tree.
- **`bin/tree-toggle.sh`** opens the session tree in every tab at once. Left to the plugin it is
  added on first visit, which resizes the tab and makes whatever runs there redraw.
- **`bin/fix-widths.sh`** runs on `window-resized` and `after-kill-pane`. tmux scales panes with
  the terminal, which squeezes the trees on a smaller screen.
- **`@treemux-tree-nvim-init-file`** must point at `~/.config/nvim-starbase/init.lua` (our
  wrapper), which loads the plugin's own init and then adds the look and the editor.
- **Hooks commands run from hooks do not fire hooks.** Anything that must react to a pane change
  made by a hook has to be called explicitly.

## Plugins

Cloned into `plugins/` (ignored by git), pinned to a commit in `install.sh`. Nothing updates on
its own.

| Plugin | Local patch |
|---|---|
| `sandudorogan/tmux-pane-tree` | `patches/tmux-pane-tree-look.patch`: icons on session and window rows, muted tree lines, bold session names |
| `kiyoon/treemux` | none |
| `tmux-plugins/tmux-resurrect`, `tmux-plugins/tmux-continuum` | none |

### Updating a plugin

Only when something is broken or a wanted change landed upstream.

1. Read what changed upstream between the pinned commit and the target.
2. In `plugins/<plugin>`: `git stash` (if it carries the patch), `git fetch`,
   `git checkout <commit>`, `git stash pop`. A conflict means upstream touched the patched lines:
   redo the patch by hand or drop it.
3. Test in a sandbox: toggle both trees, switch tabs, resize the terminal, open a file from the
   file tree, save and restore.
4. Set the new commit in `install.sh` and, if the patch changed, regenerate it:
   `git -C plugins/<plugin> diff > patches/<name>.patch`.
5. Existing installs pick up a new pin only on a fresh clone of the plugin: say so in the release
   notes, with the `git -C ~/.tmux-starbase/plugins/<plugin> checkout <commit>` line to run.

### The tmux-pane-tree patch

Most of it is proposed upstream as options (`@tmux_pane_tree_icon_session`,
`@tmux_pane_tree_icon_window`, `@tmux_pane_tree_color_tree`) in
[sandudorogan/tmux-pane-tree#18](https://github.com/sandudorogan/tmux-pane-tree/pull/18). If it is
merged: pin the merged commit, set those options in `tmux/starbase.conf` (icons U+F07B and U+F120,
color `#4a5a78`) and shrink the patch to the one line that makes session names bold, or drop it.
