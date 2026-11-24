#!/usr/bin/env bash
# Reads the Squadron `directive:*` labels of an issue and exports them to the rest of the job
# through $GITHUB_ENV:
#   SQUADRON_SKIP_REQUIREMENTS_CHECK=true|false  (`directive:skip-requirements-check`)
#   SQUADRON_MODEL=<model id> or empty            (`directive:use-model-<model>-cost-<tier>`)
# Usage: read-issue-directives.sh <issue.json from `gh issue view --json labels`>
set -euo pipefail

issue_json="$1"
models_file="$(dirname "${BASH_SOURCE[0]}")/../squadron-models.txt"

# Allowed model labels, built from the same list the setup workflow uses.
allowed=()
while read -r model cost _; do
  allowed+=("directive:use-model-$model-cost-$cost")
done < <(tr -d '\r' < "$models_file" | grep -vE '^[[:space:]]*(#|$)')

skip=false
model=''
# Sorted, so the choice is stable when several model labels are present.
while IFS= read -r label; do
  case "$label" in
    directive:skip-requirements-check)
      skip=true
      ;;
    directive:use-model-*)
      if [[ " ${allowed[*]} " != *" $label "* ]] ||
        [[ ! "$label" =~ ^directive:use-model-([a-z0-9][a-z0-9.-]*)-cost-(low|medium|high)$ ]]; then
        echo "::warning::Ignoring label $label: its model is not listed in .github/squadron-models.txt."
      elif [[ -n "$model" ]]; then
        echo "::warning::Several model labels are set; using $model and ignoring $label."
      else
        model="${BASH_REMATCH[1]}"
      fi
      ;;
  esac
done < <(jq -r '.labels[].name' "$issue_json" | tr -d '\r' | LC_ALL=C sort)

if [[ "$skip" == 'true' ]]; then
  echo '::notice::directive:skip-requirements-check is set: the requirements check is skipped.'
fi
if [[ -n "$model" ]]; then
  echo "::notice::Copilot uses model $model for this issue."
fi
{
  echo "SQUADRON_SKIP_REQUIREMENTS_CHECK=$skip"
  echo "SQUADRON_MODEL=$model"
} >> "$GITHUB_ENV"
