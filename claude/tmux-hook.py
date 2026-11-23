#!/usr/bin/python3
"""Claude Code hook for sessions running inside tmux. Does two things:

1. Records the conversation id on the pane (@claude_session), so a restore after a reboot can
   type the exact `claude --resume <id>` for that tab.
2. On Stop and Notification, tells the user which tab wants attention: the tab turns red in the
   status bar, a message shows in tmux, and the viewing terminal gets a desktop notification
   (OSC 9; Ghostty only shows it while its window is not focused).

Registered by install-claude-hooks.py. Never fails the hook: any error just exits quietly.
"""
import json
import os
import subprocess
import sys

TMUX = "tmux"
pane = os.environ.get("TMUX_PANE")


def tmux(*args):
    return subprocess.run([TMUX, *args], capture_output=True, text=True).stdout.strip()


def main():
    if not pane or not os.environ.get("TMUX"):
        return
    data = json.load(sys.stdin)
    event = data.get("hook_event_name", "")

    if event == "SessionEnd":
        tmux("set", "-pu", "-t", pane, "@claude_session")
        return
    if data.get("session_id"):
        tmux("set", "-p", "-t", pane, "@claude_session", data["session_id"])

    if event == "Stop":
        what = "finished"
    elif event == "Notification":
        what = data.get("message", "needs you")
        if "waiting for your input" in what:
            return  # the idle reminder repeats what Stop already announced
    else:
        return

    where, attached, window_active, pane_active, pane_tty = tmux(
        "display", "-p", "-t", pane,
        "#{session_name} / #{window_name}\t#{session_attached}\t#{window_active}\t#{pane_active}\t#{pane_tty}",
    ).split("\t")
    text = f"{where}: {what}"
    watching = attached != "0" and window_active == "1" and pane_active == "1"

    if not watching:
        # a bell from the pane flags its tab (red in the status bar) until it is visited
        with open(pane_tty, "w") as tty:
            tty.write("\a")
    for line in tmux("list-clients", "-F", "#{client_name}\t#{client_tty}").splitlines():
        name, client_tty = line.split("\t")
        if not watching:
            tmux("display-message", "-c", name, "-d", "6000", f" Claude · {text} ")
        try:
            with open(client_tty, "w") as tty:
                tty.write(f"\033]9;Claude · {text}\a")
        except OSError:
            pass


try:
    main()
except Exception:
    pass
