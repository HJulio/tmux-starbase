# Porting to Linux

tmux-starbase is built and tested on macOS. Nothing in the design is Mac-only: the UI is tmux, and
the plugins it uses run on Linux. What ties it to macOS is a handful of commands in the scripts.
This is the list a port has to work through; pull requests are welcome.

| Where | macOS-specific | On Linux |
|---|---|---|
| `install.sh` | Refuses to run outside macOS; installs with Homebrew; assumes `/usr/bin/python3` has `pip` | Install `tmux` (3.3+), `bash` 4+, `neovim`, `fzf`, `git`, `python3` + `pynvim`, `lsof` with the distro's package manager |
| `install.sh --autostart` | Writes a launchd agent | A systemd user unit running `~/.tmux-starbase/bin/starbase`, plus `loginctl enable-linger` to start without a login |
| `bin/sysstat.sh` | `macmon` for CPU, temperature and memory; `stat -f %m` for the cache age | `/proc/stat`, `/proc/meminfo`, `sensors` or `/sys/class/thermal`; `stat -c %Y` |
| `bin/client-where.sh` | `ps eww` to read the client's environment, `ps -o lstart=` | `/proc/<pid>/environ`; `ps -o lstart=` works |
| `bin/motd.sh` | `sysctl vm.loadavg`, `sysctl hw.ncpu`, `memory_pressure`, `df` on `/System/Volumes/Data` | `/proc/loadavg`, `nproc`, `free`, `df /` |
| `bin/lib.sh` | Looks for Tailscale inside `/Applications` and for OrbStack's docker | Already falls back to `tailscale` and `docker` on the `PATH`; nothing to do |
| `bin/preview` | Prints an `open http://...` line for the client | `xdg-open` on a Linux client |
| `tmux/starbase.conf` | `set-environment -g PATH` lists the Homebrew prefixes | Add the distro's paths, or drop the line if the server always starts from a login shell |
| `tmux/starbase.conf` | `Option+1..9` and `Option+Shift+arrows` rely on the terminal sending Option as Meta | Alt works out of the box on most Linux terminals |
| `@treemux-python-command` | `/usr/bin/python3` | The python that has `pynvim` |

Things that should work unchanged: the status bar, the menu, both trees, the Claude Code hooks,
snapshots and restore, the tailnet and containers menus, the client snippets.

The suggested route: make `install.sh` branch on `uname`, move the probes above into `bin/lib.sh`
as small functions with a macOS and a Linux body, and keep everything else shared.
