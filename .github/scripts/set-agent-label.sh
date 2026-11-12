#!/usr/bin/env bash
# Hands a Squadron pull request to one agent: removes every agent:* label, then adds
# AGENT_LABEL (which fires the `labeled` event that starts that agent). An empty
# AGENT_LABEL only clears the labels, which is how a running agent consumes its trigger.
set -euo pipefail

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"
: "${PR_NUMBER:?PR_NUMBER is required}"
AGENT_LABEL="${AGENT_LABEL:-}"

case "$AGENT_LABEL" in
  ''|agent:coder|agent:reviewer|agent:tester) ;;
  *)
    printf 'Unsupported agent label: %s\n' "$AGENT_LABEL" >&2
    exit 1
    ;;
esac

endpoint="repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/labels"
current_agent_labels="$(gh api "$endpoint?per_page=100" --jq '.[].name | select(startswith("agent:"))')"
for label in $current_agent_labels; do
  gh api --method DELETE "$endpoint/$label" --silent
done

if [[ -n "$AGENT_LABEL" ]]; then
  gh api --method POST "$endpoint" -f "labels[]=$AGENT_LABEL" --silent
fi
