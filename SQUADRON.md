# Squadron Template Context

This file documents the template itself. The product generated from this template may replace `README.md`; keep template architecture, setup, and maintenance guidance here.

## Purpose

Squadron is a GitHub Actions template for a product workflow run by three AI engineering roles: coder, reviewer, and tester. The workflows use GitHub Copilot CLI for engineering tasks and issue labels for status tracking; they do not depend on GitHub Projects.

## Workflow Lifecycle

1. Add `status:todo` to an issue when work should start. The coder workflow runs automatically on that label; no `agent:coder` label is needed on the issue.
2. The coder changes the issue status label to `status:in-progress`, implements the issue, updates documentation affected by the change, and opens a pull request containing `Closes #<issue-number>`. The issue remains in progress while the PR is reviewed, and the coder queues review by applying `agent:reviewer` to the PR.
3. The reviewer consumes the `agent:reviewer` label when a review starts. It reviews code and relevant documentation against the issue, then posts a verdict comment. If there are no blocking findings, the issue status label becomes `status:testing` and the PR receives `agent:tester`. Otherwise, the issue status label becomes `status:in-progress` and the PR receives `agent:coder` so the coder can fix that same PR. After pushing fixes, the coder reapplies `agent:reviewer` to queue a new review.
4. The tester uses only the linked issue title and body as its requirements source; it does not consult documentation, PR descriptions, review comments, or other agent summaries. It may inspect implementation code and existing tests only to locate test setup and entry points. It adds or updates tests under the configured test pathspecs, ensures the exact `SQUADRON_TEST_COMMAND` is configured, launches it, fixes test-only failures, and reruns it until it passes or identifies a product defect for the coder. If an npm script is missing, it adds the script to `package.json`, reusing the existing test runner or adding a suitable test dependency and updating the lockfile. It never uses a no-op command or weakens tests to force a pass. The workflow installs dependencies and runs the configured command again after publishing test changes; only then does it attempt the merge. If the command fails, it includes the last 80 log lines in its PR comment, changes the issue status to `status:in-progress`, and queues the coder on that PR. On success it directly squash-merges the PR. The issue status label becomes `status:done` after GitHub reports the PR merged.

The reviewer verdict is a PR comment, not a formal GitHub approval review. Branch protection and required checks remain authoritative. Any required checks other than the tester's own test command must already pass before its direct merge step can succeed.

## Workflow Ownership

- `.github/workflows/coder.yml` listens for issue and PR events. New issues start on `status:todo`; PR labels route to only the matching coder-fix, reviewer, or tester job, so one label event creates one workflow run.
- `.github/workflows/reviewer.yml` and `.github/workflows/tester.yml` are reusable role workflows called by coder.yml, not direct event listeners. Reviewer handles review and queues rework or testing; tester launches `SQUADRON_TEST_COMMAND`, fixes test-only failures, and reruns it before the workflow's final test gate. Successful tests allow a squash merge. Tester pushes do not start review.
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
- `SQUADRON_TEST_PATHS`: `**/*.test.*,**/*.spec.*`

The status helper removes existing `status:*` labels and applies the requested status label, preserving unrelated labels. No project, project ID, or project status field is required.

Repository setup checklist:

- Create the `agent:coder`, `agent:reviewer`, and `agent:tester` labels. `agent:coder` is applied to an existing PR when it needs rework; `status:todo` starts new issue work.
- Configure the required secrets and repository variables above.
- Ensure the `SQUADRON_GITHUB_TOKEN` token has write access to this repository and that repository rules permit it to push to PR branches.
- Set `SQUADRON_TEST_PATHS` and `SQUADRON_TEST_COMMAND` to match the product's language, test layout, and test runner when the defaults do not fit.
- Configure branch protection and required checks. Any checks besides the tester's test command must pass before the tester's direct merge step.

## Security and Operating Boundaries

- Apply `status:todo` only to issues that should be processed. Copilot CLI can edit files and run tools, but the GitHub write token is not present in its execution step.
- Reviewer and tester workflows only process PRs whose head repository is the current repository; fork PRs are not given the automation credentials.
- The tester commits files matched by `SQUADRON_TEST_PATHS` plus changed `package.json` or npm lockfiles needed to configure its test command; other working-tree changes from the AI step are discarded.
- Configured test pathspecs with no matching files are skipped. The default matches `*.test.*` and `*.spec.*` files anywhere in the repository, including root-level tests; the tester fails with a clear error if none of its configured paths match.
- Tester requirements come from the linked issue title/body only. It must not depend on documentation or summaries produced by the coder or reviewer.
- The reviewer result is model-generated. Treat it as automation feedback, not a substitute for required human review or branch protection.
- The tester does not move an issue to Done merely because tests pass; the PR must actually merge first.

## Template Maintenance

- Keep this document focused on the reusable template. Product-specific behavior belongs in the generated product's documentation.
- `README.md` is product-facing and may be replaced during product creation; do not rely on it as the sole copy of these template instructions.
- When changing coder.yml routing, reusable role workflows, labels, status transitions, token use, or defaults, update this document and keep the workflows and shared status helper consistent.
- Copilot CLI is pinned in the workflow files. Review and update that pin deliberately when upgrading the automation runtime.
