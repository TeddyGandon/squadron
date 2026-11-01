# Usage

GitHub Actions pipelines for a three-role AI engineering workflow using issue labels, without a GitHub Project dependency.

## Workflow

1. Add `status:todo` to a backlog issue and apply `agent:coder` when work should start.
2. The coder changes the issue status label to `status:in-progress`, implements the issue, updates relevant documentation, and opens a pull request. The issue remains in progress during review.
3. The reviewer checks the code and relevant documentation against the issue, then posts a verdict. A validated pull request changes the issue label to `status:testing` and receives the `agent:tester` label. A rejected pull request changes the issue label to `status:in-progress` and receives the `agent:coder` label so the coder can fix the existing PR.
4. The tester uses only the issue title and body as its requirements source, not documentation or prior agent summaries. It adds tests under the configured test paths and runs the configured test command. If the test command fails, it reports the output, returns the issue to `status:in-progress`, and queues the coder on the existing PR. After success, it enables squash auto-merge. Once GitHub merges the pull request, the issue label changes to `status:done`.

The reviewer verdict is posted as a pull request comment; it is not a GitHub approval review. Repository branch protection and required checks remain authoritative.

## Configuration

Create these repository secrets:

- `COPILOT_GITHUB_TOKEN`: a token authorized to use GitHub Copilot. It is only provided to the Copilot CLI steps.
- `SQUADRON_GITHUB_TOKEN`: a fine-grained token granted access to this repository with **Contents: Read and write**, **Pull requests: Read and write**, and **Issues: Read and write**. Approve it for the organization if required. It is used for pull requests, labels, comments, test commits, coder fixes, and merges.

Create these repository labels:

- Agent triggers: `agent:coder`, `agent:reviewer`, `agent:tester`.
- Issue statuses: `status:todo`, `status:in-progress`, `status:testing`, `status:done`.

Set these optional repository variables when the defaults do not fit the product:

- `SQUADRON_TEST_COMMAND`: defaults to `npm run test`.
- `SQUADRON_TEST_PATHS`: defaults to `tests,src/**/*.test.ts`.

The status helper replaces any existing `status:*` label with the requested status label and preserves all unrelated issue labels. No project, project ID, or project status field is required.

Enable squash auto-merge in repository settings. Configure branch protection and required checks; the tester enables auto-merge only after its test command succeeds, and GitHub completes the merge when all repository rules pass.
