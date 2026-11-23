#!/bin/bash
# Opens a menu on the client given as $1 with the running containers.
# Choosing one shows its logs in a popup; q or Ctrl+C closes it.
. "${STARBASE_HOME:-$HOME/.tmux-starbase}/bin/lib.sh"
DOCKER=$(docker_bin)
client=$1
[ -n "$DOCKER" ] || { tmux display-message -c "$client" " docker is not installed "; exit 0; }

items=()
while IFS=$'\t' read -r name status; do
  [ -n "$name" ] || continue
  items+=("$name  ($status)" "" "display-popup -E -w 90% -h 80% -T ' $name ' '$DOCKER logs --tail 200 -f $name'")
done < <("$DOCKER" ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null | sort)

if [ ${#items[@]} -eq 0 ]; then
  tmux display-message -c "$client" " No containers running "
  exit 0
fi
tmux display-menu -c "$client" -T "#[align=centre] containers · $(( ${#items[@]} / 3 )) running " -x C -y C "${items[@]}"
