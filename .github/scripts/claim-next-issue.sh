#!/usr/bin/env bash
# Squadron works on one issue at a time. This processes the whole queue, not only the issue
# whose label triggered it, because GitHub keeps only the newest pending run of a concurrency
# group and cancels older pending ones: the run that does execute must cover every queued issue.
#
# - If an open issue is `status:in-progress` or `status:testing` (without `status:todo`), the
#   pipeline is busy and nothing starts.
# - Otherwise it starts one issue: first a retry (an in-progress/testing issue someone re-applied
#   `status:todo` to), else the oldest `status:todo` issue (lowest number). Starting means
#   setting `status:in-progress` and writing `issue` and `title` to GITHUB_OUTPUT for the coder.
# - Every other `status:todo` issue gets a queue comment once per wait.
set -euo pipefail

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
queued_marker='<!-- squadron-queued -->'

issues="$(gh issue list --repo "$GITHUB_REPOSITORY" --state open --limit 1000 \
  --json number,labels --jq '[.[] | {number, labels: [.labels[].name]}]')"
select_numbers() {
  jq -r "[.[] | select($1) | .number] | sort | .[]" <<< "$issues"
}
active='(.labels | index("status:in-progress") or index("status:testing"))'
todo='(.labels | index("status:todo"))'
mapfile -t busy < <(select_numbers "$active and ($todo | not)")
mapfile -t retries < <(select_numbers "$active and $todo")
mapfile -t queued < <(select_numbers "$todo and ($active | not)")

started=''
if ((${#busy[@]} == 0)); then
  if ((${#retries[@]} > 0)); then
    started="${retries[0]}"
  elif ((${#queued[@]} > 0)); then
    started="${queued[0]}"
    queued=("${queued[@]:1}")
  fi
fi

if [[ -n "$started" ]]; then
  ISSUE_NUMBER="$started" STATUS_LABEL=status:in-progress bash "$here/set-issue-status-label.sh" > /dev/null
  title="$(gh issue view "$started" --repo "$GITHUB_REPOSITORY" --json title --jq '.title')"
  {
    echo 'claimed=true'
    echo "issue=$started"
    echo "title=${title//$'\n'/ }"
  } >> "$GITHUB_OUTPUT"
  holder="$started"
  printf 'Started issue #%s.\n' "$started"
else
  echo 'claimed=false' >> "$GITHUB_OUTPUT"
  holder="${busy[0]:-${retries[0]:-}}"
  echo 'No issue started: the pipeline is busy or the queue is empty.'
fi

if ((${#queued[@]} == 0)); then
  exit 0
fi
squadron_login="$(gh api user --jq '.login')"
for number in "${queued[@]}"; do
  # Comment once per wait: skip if the latest Squadron comment is already the queue notice.
  last="$(gh api --paginate "repos/$GITHUB_REPOSITORY/issues/$number/comments" \
    --jq ".[] | select(.user.login == \"$squadron_login\") | .body | @json" | tail -n 1)"
  if [[ "$last" == *"$queued_marker"* ]]; then
    continue
  fi
  gh issue comment "$number" --repo "$GITHUB_REPOSITORY" --body \
    "Squadron is working on #$holder and handles one issue at a time to avoid merge conflicts. This issue stays \`status:todo\` and starts automatically when the pipeline is free (oldest queued issue first).

$queued_marker" > /dev/null
  printf 'Queued issue #%s.\n' "$number"
done
