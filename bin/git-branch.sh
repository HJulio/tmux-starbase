#!/bin/bash
# Pane border: prints the git branch of the directory given as $1, or nothing outside a repo.
branch=$(git -C "$1" branch --show-current 2>/dev/null)
[ -n "$branch" ] && printf ' \xee\x82\xa0 %s' "$branch"
