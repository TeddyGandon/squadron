#!/usr/bin/env bash
# Squadron works on one issue at a time. When an issue leaves the pipeline (merged, closed,
# abandoned, or sent back for requirements), this starts the oldest queued `status:todo` issue
# by re-applying its label, which fires the `labeled` event that starts the coder. GH_TOKEN
# must be SQUADRON_GITHUB_TOKEN: labels set with the default GITHUB_TOKEN start no workflow.
set -euo pipefail

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"

for status in status:in-progress status:testing; do
  busy="$(gh issue list --repo "$GITHUB_REPOSITORY" --state open --label "$status" --limit 1 \
    --json number --jq '.[].number')"
  if [[ -n "$busy" ]]; then
    printf 'Issue #%s is still %s; the queue waits for it.\n' "$busy" "$status"
    exit 0
  fi
done

next="$(gh issue list --repo "$GITHUB_REPOSITORY" --state open --label status:todo --limit 1000 \
  --json number --jq 'map(.number) | min // empty')"
if [[ -z "$next" ]]; then
  echo 'No queued issue to start.'
  exit 0
fi

printf 'Starting queued issue #%s.\n' "$next"
endpoint="repos/$GITHUB_REPOSITORY/issues/$next/labels"
gh api --method DELETE "$endpoint/status:todo" --silent
gh api --method POST "$endpoint" -f 'labels[]=status:todo' --silent
