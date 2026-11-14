#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"
: "${ISSUE_NUMBER:?ISSUE_NUMBER is required}"
: "${STATUS_LABEL:?STATUS_LABEL is required}"

case "$STATUS_LABEL" in
  status:todo|status:in-progress|status:testing|status:done) ;;
  *)
    printf 'Unsupported issue status label: %s\n' "$STATUS_LABEL" >&2
    exit 1
    ;;
esac

status_labels='["status:todo", "status:in-progress", "status:testing", "status:done"]'
current_labels="$(gh api "repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER/labels?per_page=100" --jq '[.[].name]')"
updated_labels="$(jq --argjson status_labels "$status_labels" --arg status_label "$STATUS_LABEL" \
  '{labels: ([.[] as $label | select(($status_labels | index($label)) == null) | $label] + [$status_label])}' \
  <<< "$current_labels")"

gh api --method PUT "repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER/labels" \
  --input - <<< "$updated_labels" \
  --jq '.[].name'