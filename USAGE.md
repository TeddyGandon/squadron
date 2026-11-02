![Logo](logo.svg)

GitHub Actions pipelines for a three-role AI engineering workflow using issue labels, without a GitHub Project dependency.

## Workflow

1. Add `status:todo` to a backlog issue and apply `agent:coder` when work should start.
2. The coder changes the issue status label to `status:in-progress`, implements the issue, updates relevant documentation, and opens a pull request. The issue remains in progress during review.
3. The reviewer checks the code and relevant documentation against the issue, then posts a verdict. A validated pull request changes the issue label to `status:testing` and receives the `agent:tester` label. A rejected pull request changes the issue label to `status:in-progress` and receives the `agent:coder` label so the coder can fix the existing PR.
4. The tester uses only the issue title and body as its requirements source, not documentation or prior agent summaries. It installs npm dependencies when a project manifest exists, adds tests under the configured test paths, and runs `SQUADRON_TEST_COMMAND` (default `npm run test`). The workflow reruns the command after publishing tests and only merges after it passes. If it fails, the tester reports the output, returns the issue to `status:in-progress`, and queues the coder on the existing PR. After success, it directly squash-merges the PR. Once GitHub merges the pull request, the issue label changes to `status:done`.

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

Unmatched entries in `SQUADRON_TEST_PATHS` are ignored, so repositories do not need to contain every default test path. At least one configured path must match files for the tester to stage its changes.

Configure branch protection and required checks. The tester directly merges after its test command succeeds, so any other required checks must already be passing.
