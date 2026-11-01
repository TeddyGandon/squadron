# Squadron Template Context

This file documents the template itself. The product generated from this template may replace `README.md`; keep template architecture, setup, and maintenance guidance here.

## Purpose

Squadron is a GitHub Actions template for a product workflow run by three AI engineering roles: coder, reviewer, and tester. The workflows use GitHub Copilot CLI for engineering tasks and issue labels for status tracking; they do not depend on GitHub Projects.

## Workflow Lifecycle

1. Add `status:todo` to a backlog issue. Apply `agent:coder` when work should start.
2. The coder changes the issue status label to `status:in-progress`, implements the issue, updates documentation affected by the change, and opens a pull request containing `Closes #<issue-number>`. The issue remains in progress while the PR is reviewed, and the coder labels the PR `agent:reviewer`.
3. The reviewer runs for the reviewer label and subsequent PR updates. It reviews code and relevant documentation against the issue, then posts a verdict comment. If there are no blocking findings, the issue status label becomes `status:testing` and the PR receives `agent:tester`. Otherwise, the issue status label becomes `status:in-progress` and the PR receives `agent:coder` so the coder can fix that same PR.
4. The tester uses only the linked issue title and body as its requirements source; it does not consult documentation, PR descriptions, review comments, or other agent summaries. It may inspect implementation code and existing tests only to locate test setup and entry points. It adds or updates tests under the configured test pathspecs, publishes those test changes, and runs the configured test command. If the test command fails, it includes the last 80 log lines in its PR comment, changes the issue status to `status:in-progress`, and queues the coder on that PR. On success it enables squash auto-merge. The issue status label becomes `status:done` after GitHub reports the PR merged.

The reviewer verdict is a PR comment, not a formal GitHub approval review. Branch protection and required checks remain authoritative. Auto-merge may wait for those requirements.

## Workflow Ownership

- `.github/workflows/coder.yml` starts on an issue receiving `agent:coder` or a same-repository PR receiving `agent:coder`. The issue path implements a new task and opens a PR; the PR path applies feedback to the existing branch, then pushes changes to retrigger review.
- `.github/workflows/reviewer.yml` handles reviewer-labeled, reopened, ready-for-review, and synchronized PRs from the same repository. It clears an earlier tester queue before reviewing code and docs against the linked issue, posts the result, updates the issue status label, queues testing on a validated result, and queues the coder on rejection. Fork PRs are ignored.
- `.github/workflows/tester.yml` starts when a PR receives `agent:tester`. It stages only configured test paths, publishes test changes, and runs the test command. A test-command failure reports logs, sets the issue to In Progress, and queues the coder; success enables squash auto-merge. Its merged-PR event marks the issue Done.
- `.github/scripts/set-issue-status-label.sh` replaces the issue's current status label with the requested one while preserving unrelated labels.

Keep the PR body closing reference intact: reviewer and tester workflows use `Closes #<number>` to locate the issue. Keep all agent and status labels listed below available in the repository.

## GitHub Configuration

Create these repository secrets:

- `COPILOT_GITHUB_TOKEN`: a token authorized to use GitHub Copilot. It is passed to Copilot CLI steps, with secret redaction enabled.
- `SQUADRON_GITHUB_TOKEN`: a fine-grained token granted access to this repository with **Contents: Read and write**, **Pull requests: Read and write**, and **Issues: Read and write**. It is used for PR creation, labels, comments, pushing tests and coder fixes, and merges. Approve the token for the organization if required. Use this token rather than `GITHUB_TOKEN` for operations that must trigger subsequent workflows.

Create these repository labels:

- Agent triggers: `agent:coder`, `agent:reviewer`, `agent:tester`.
- Issue statuses: `status:todo`, `status:in-progress`, `status:testing`, `status:done`.

These repository variables are optional overrides; the values shown are used when they are unset:

- `SQUADRON_TEST_COMMAND`: `npm run test`
- `SQUADRON_TEST_PATHS`: `tests,src/**/*.test.ts`

The status helper removes existing `status:*` labels and applies the requested status label, preserving unrelated labels. No project, project ID, or project status field is required.

Repository setup checklist:

- Create the `agent:coder`, `agent:reviewer`, and `agent:tester` labels. `agent:coder` is applied to an issue to start work and to an existing PR when it needs rework.
- Configure the required secrets and project variables above.
- Ensure the `SQUADRON_GITHUB_TOKEN` token has write access to this repository and that repository rules permit it to push to PR branches.
- Set `SQUADRON_TEST_PATHS` and `SQUADRON_TEST_COMMAND` to match the product's language, test layout, and test runner when the defaults do not fit.
- Enable squash auto-merge in repository settings and configure branch protection and required checks.

## Security and Operating Boundaries

- Apply `agent:coder` only to issues that should be processed. Copilot CLI can edit files and run tools, but the GitHub write token is not present in its execution step.
- Reviewer and tester workflows only process PRs whose head repository is the current repository; fork PRs are not given the automation credentials.
- The tester commits only files matched by `SQUADRON_TEST_PATHS`; other working-tree changes from the AI step are discarded.
- Configured test pathspecs with no matching files are skipped, so a repository need not contain every default test directory or pattern. The tester fails with a clear error if none of its configured paths match.
- Tester requirements come from the linked issue title/body only. It must not depend on documentation or summaries produced by the coder or reviewer.
- The reviewer result is model-generated. Treat it as automation feedback, not a substitute for required human review or branch protection.
- The tester does not move an issue to Done merely because tests pass; the PR must actually merge first.

## Template Maintenance

- Keep this document focused on the reusable template. Product-specific behavior belongs in the generated product's documentation.
- `README.md` is product-facing and may be replaced during product creation; do not rely on it as the sole copy of these template instructions.
- When changing a workflow's trigger, label, status transition, token use, or default, update this document and keep the three workflows and shared status helper consistent.
- Copilot CLI is pinned in the workflow files. Review and update that pin deliberately when upgrading the automation runtime.
