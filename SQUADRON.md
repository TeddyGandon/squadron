# Squadron Template Context

This file documents the template itself. The product generated from this template may replace `README.md`; keep template architecture, setup, and maintenance guidance here. User-facing setup steps live in [USAGE.md](USAGE.md).

## Purpose

Squadron is a GitHub Actions template for a product workflow run by three AI engineering roles: coder, reviewer, and tester. The workflows use GitHub Copilot CLI for engineering tasks and issue labels for status tracking; they do not depend on GitHub Projects.

## Workflow Lifecycle

1. Adding `status:todo` to an open issue starts the coder. No `agent:coder` label is needed on the issue.
2. The coder sets `status:in-progress`, implements the issue, updates affected documentation, and opens a pull request from branch `squadron/issue-<number>` whose body contains `Closes #<number>`. It queues review by applying `agent:reviewer` to the PR.
3. The reviewer consumes `agent:reviewer`, reviews code and documentation against the issue, and posts a verdict comment starting with `## Squadron automated review`. Without blocking findings, the issue becomes `status:testing` and the PR receives `agent:tester`. Otherwise the issue becomes `status:in-progress` and the PR receives `agent:coder`; the coder consumes that label, fixes the same PR using the latest review or tester comment, pushes, and reapplies `agent:reviewer`.
4. The tester consumes `agent:tester` and uses only the linked issue title and body as its requirements source; it does not consult documentation, PR descriptions, review comments, or other agent summaries. It may inspect implementation code and existing tests only to locate test setup and entry points. It adds or updates tests matching `SQUADRON_TEST_PATHS`, ensures the exact `SQUADRON_TEST_COMMAND` is configured (adding a missing npm script or test dependency and updating the lockfile if needed), launches it, and fixes test-only failures. It never uses a no-op command or weakens tests. If existing tests already cover the issue it may make no changes. The workflow commits only test files and npm manifest/lockfile changes, discards everything else, reinstalls dependencies, and runs the command as the merge gate.
5. On success the tester squash-merges the PR, or enables auto-merge when a direct merge is blocked (for example by required checks pending on its test commit). On failure it comments the last 80 log lines (starting with `Squadron tester failed`), sets `status:in-progress`, and queues the coder. When GitHub reports the PR merged, the issue becomes `status:done`.

The reviewer verdict is a PR comment, not a formal GitHub approval review. Branch protection and required checks remain authoritative.

Any failed job comments on its issue or PR with a run link and the label to re-apply to retry. Because every agent consumes its trigger label when it starts, re-applying the label is always enough to retry.

## Workflow Ownership

- `.github/workflows/coder.yml` (workflow name **Squadron**) is the only event listener. It handles `issues: labeled` and `pull_request: labeled|closed`, and starts at most one job per event: `coder` (issue gets `status:todo`), `coder-fix` (`agent:coder`), `reviewer` (`agent:reviewer`), `tester` (`agent:tester`), or `mark-done` (PR merged). PR jobs only run for open, same-repository PRs from `squadron/issue-<number>` branches; the issue number comes from that branch name. Jobs are serialized per issue and per PR with job-level concurrency groups.
- `.github/workflows/reviewer.yml` and `.github/workflows/tester.yml` are reusable role workflows called by coder.yml, not direct event listeners.
- `.github/workflows/setup.yml` is a manual one-time workflow that creates labels and checks secrets.
- `.github/scripts/set-issue-status-label.sh` replaces the issue's `status:*` label with the requested one while preserving unrelated labels.
- `.github/scripts/set-agent-label.sh` removes every `agent:*` label from a PR and optionally adds one, which fires the `labeled` event that starts the next agent.
- `.github/scripts/extract-review-report.py` extracts the reviewer's JSON verdict from Copilot output and renders the review comment.
- `.github/scripts/install-dependencies.sh` runs `npm ci` or `npm install` when the project has a `package.json`.

Every job checks out the default branch to `squadron/` and runs helper scripts from there with `bash`, so scripts never come from the PR under review and do not need an executable bit. Product code is checked out to `product/`, where Copilot runs.

## GitHub Configuration

See [USAGE.md](USAGE.md#setup) for secrets, the setup workflow, and optional variables:

- Secrets: `COPILOT_GITHUB_TOKEN`, `SQUADRON_GITHUB_TOKEN` (Contents, Pull requests, Issues: Read and write).
- Labels: `agent:coder`, `agent:reviewer`, `agent:tester`, `status:todo`, `status:in-progress`, `status:testing`, `status:done`. The issue forms only apply `status:todo` if it exists, so run the setup workflow first.
- Variables: `SQUADRON_TEST_COMMAND` (default `npm run test`), `SQUADRON_TEST_PATHS` (default `**/*.test.*,**/*.spec.*`, git glob patterns).

`SQUADRON_GITHUB_TOKEN` is used for every write so its actions trigger the next workflow; the default `GITHUB_TOKEN` stays read-only (it only writes labels in the setup workflow).

## Security and Operating Boundaries

- Apply `status:todo` only to issues that should be processed. Copilot CLI can edit files and run tools, but `SQUADRON_GITHUB_TOKEN` is never present in a Copilot step, and `COPILOT_GITHUB_TOKEN` is stripped from Copilot's shell environment with `--secret-env-vars`.
- Fork PRs and PRs from other branches are never given the automation credentials.
- Agent changes under `.github/workflows` are discarded before publishing, so the token does not need the Workflows permission.
- The tester commits only files matching `SQUADRON_TEST_PATHS` (excluding `node_modules`) plus `package.json` and npm lockfiles; other working-tree changes are discarded.
- The reviewer result is model-generated. Treat it as automation feedback, not a substitute for required human review or branch protection.
- An issue becomes `status:done` only after its PR actually merges.

## Template Maintenance

- Keep this document focused on the reusable template. Product-specific behavior belongs in the generated product's documentation.
- `README.md` is product-facing and may be replaced during product creation; do not rely on it as the sole copy of these template instructions.
- When changing coder.yml routing, role workflows, labels, status transitions, token use, comment prefixes, or defaults, update this document and USAGE.md and keep the workflows and helper scripts consistent.
- The coder-fix job selects feedback by the comment prefixes `## Squadron automated review` and `Squadron tester failed`; keep them in sync with the reviewer and tester.
- Copilot CLI is pinned (`@github/copilot@1.0.105`) in coder.yml, reviewer.yml, and tester.yml. Update all pins together and deliberately.
- `.gitignore` excludes `node_modules/` so agents never commit installed dependencies; keep that entry when products extend it.
