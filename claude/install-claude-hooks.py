#!/usr/bin/python3
"""Registers this setup's Claude Code hooks in ~/.claude/settings.json. Idempotent.

- tmux-pane-tree's hook: agent status badges in the session tree. The plugin's own installer is
  not used because it also writes into Cursor, Kiro, opencode and pi, and overwrites the Codex
  `notify` line.
- tmux-hook.py: attention notifications and the per-tab conversation id.
"""
import json
import os
import shutil

SETTINGS = os.path.expanduser("~/.claude/settings.json")
HOOKS = {
    os.path.expanduser("~/.tmux-starbase/plugins/tmux-pane-tree/scripts/features/hooks/hook-claude.sh"): [
        "SessionStart", "UserPromptSubmit", "Stop", "SubagentStop", "Notification",
        "PermissionRequest", "SessionEnd", "SubagentStart",
    ],
    os.path.expanduser("~/.tmux-starbase/claude/tmux-hook.py"): [
        "SessionStart", "UserPromptSubmit", "Stop", "Notification", "SessionEnd",
    ],
}

settings = json.load(open(SETTINGS)) if os.path.exists(SETTINGS) else {}
hooks = settings.setdefault("hooks", {})
added = 0
for command, events in HOOKS.items():
    for event in events:
        groups = hooks.setdefault(event, [])
        if any(h.get("command") == command for g in groups for h in g.get("hooks", [])):
            continue
        hook = {"type": "command", "command": command, "timeout": 10}
        if event != "SessionStart":
            hook["async"] = True
        groups.append({"matcher": "", "hooks": [hook]})
        added += 1

if added:
    if os.path.exists(SETTINGS):
        shutil.copy(SETTINGS, SETTINGS + ".pre-starbase")
    os.makedirs(os.path.dirname(SETTINGS), exist_ok=True)
    json.dump(settings, open(SETTINGS, "w"), indent=2)
print(f"claude hooks: {added} added")
