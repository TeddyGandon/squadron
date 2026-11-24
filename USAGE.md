<div align="center">
  
  ![Logo](logo.svg)
  
</div>

GitHub Actions pipelines for a three-role AI engineering workflow using issue labels, without a GitHub Project dependency.

## Setup

1. Create these repository secrets:
   - `COPILOT_GITHUB_TOKEN`: a token authorized to use GitHub Copilot. It is only provided to the Copilot CLI steps.
   - `SQUADRON_GITHUB_TOKEN`: a fine-grained token for this repository with **Contents**, **Pull requests**, **Issues**, and **Workflows** set to **Read and write**. Approve it for the organization if required. It is used for pull requests, labels, comments, pushes, and merges; the update workflow also needs **Workflows** permission to replace workflow files.
2. Run **Actions → Squadron Setup → Run workflow**. It creates or updates the `status:*`, `agent:*`, and `directive:*` labels and checks that both secrets are present and that `SQUADRON_GITHUB_TOKEN` can write to the repository.
3. Optionally set these repository variables when the defaults do not fit the product:
   - `SQUADRON_TEST_COMMAND`: defaults to `npm run test`.
   - `SQUADRON_TEST_PATHS`: comma-separated glob patterns for test files, defaulting to `**/*.test.*,**/*.spec.*` (test and spec files anywhere, including the repository root).
4. Configure branch protection and required checks as you like. When the coder's direct merge is blocked, for example by required checks still running on the tester's commit, it enables auto-merge instead, so turn on **Settings → General → Allow auto-merge** if you use required checks.

## Update from the template

Run **Actions → Squadron Update → Run workflow** to copy the latest Squadron files from the Squadron template's default branch.

1. The workflow first compares its own file (`.github/workflows/update.yml`) with the template's. If it changed, it commits the new version as `chore: update Squadron update workflow`, relaunches itself, and stops; the relaunched run performs the update with the new version.
2. Otherwise it copies the template files explicitly listed in the workflow (the Squadron issue forms, scripts, skills, and workflows under `.github/`, plus `SQUADRON.md`, `SQUADRON-CHANGELOG.md`, and `USAGE.md`), then commits and pushes the changes as `chore: update Squadron`. If those files already match, it commits nothing.
3. It then starts **Squadron Setup**, which is safe to run any number of times: it brings the labels in line with the updated template (including deleting model labels the template no longer lists) and checks the secrets.

## Issue directives

Add these labels to an issue, before it starts, to change how the agents handle it. Every agent reads them from the issue, including on later review, test, and fix runs.

- `directive:skip-requirements-check`: the coder implements the issue directly, without the requirements check.
- `directive:use-model-<model>-cost-<low|medium|high>`: every agent (coder, reviewer, tester) runs Copilot with that model instead of the default. The cost tier shows the model's relative price. Low is under $2, medium is $2 to $8, and high is over $8 per 1M output tokens, from GitHub's per-token pricing. The models come from `.github/squadron-models.txt`, which lists models included in Copilot Pro. Use one model label per issue. If several are set, the first in alphabetical order is used.

The listed files are overwritten, so customizations in them will be lost. Other files, including your own files under `.github/` and `README.md`, are left unchanged. Files removed from the template are not deleted from your repository.

See the [changelog](SQUADRON-CHANGELOG.md) to find all the available updates.

## Workflow

1. Create an issue from the Feature, Technical task, or Bug form. The form applies `status:todo`, which queues the issue for the coder. For other issues, add `status:todo` when the issue is ready. Squadron works on one issue at a time to avoid merge conflicts between its pull requests: if another issue is `status:in-progress` or `status:testing`, the new issue gets a comment and waits, and it starts automatically when the pipeline is free (oldest queued issue first). The `squadron-requirements-helper` Copilot skill helps draft an issue that passes the coder's requirements check.
2. When the issue starts, it becomes `status:in-progress` and the coder checks that the issue's requirements and scope are complete. If something blocking is missing, it comments the questions on the issue and removes its status label without implementing anything, and the next queued issue starts: answer the questions in the issue body (agents do not read comments), then add `status:todo` again. Otherwise it implements the issue, updates relevant documentation, opens a pull request from `squadron/issue-<number>` that contains `Closes #<number>`, and queues review with `agent:reviewer`.
3. The reviewer checks the code and documentation against the issue and posts a verdict comment. On approval the issue becomes `status:testing` and the PR gets `agent:tester`; otherwise the issue returns to `status:in-progress` and the PR gets `agent:coder`. The coder then fixes the same PR and queues another review.
4. The tester uses only the issue title and body as its requirements source. It adds or updates tests matching `SQUADRON_TEST_PATHS`, makes sure `SQUADRON_TEST_COMMAND` works (adding a missing npm script or test dependency if needed), and never weakens tests or changes product code. The workflow then reinstalls dependencies and runs the command as the merge gate. On success it comments `Squadron tester passed` with the tested commit and queues the coder. The coder first checks whether the PR conflicts with its base branch. If it does, the coder resolves the conflicts, pushes a merge commit, comments the list of conflicting files, and sends the PR back to the reviewer, so the resolved code is reviewed and tested again. Otherwise it squash-merges the PR (or enables auto-merge when required checks are still running) as long as the branch has not changed since; on failure it comments the last 80 log lines, returns the issue to `status:in-progress`, and queues the coder.
5. When the PR is merged, the issue becomes `status:done`.

The reviewer verdict is a pull request comment, not a GitHub approval review. Branch protection and required checks remain authoritative.

## When something fails

Every failed run comments on the issue or pull request with a link to the run. To retry, re-apply the label named in the comment: `status:todo` on the issue for the coder, or `agent:coder`, `agent:reviewer`, or `agent:tester` on the pull request. If the coder could not merge because the branch changed after the tester passed, re-apply `agent:tester`. If it could not resolve merge conflicts, re-apply `agent:coder` to retry, or resolve them yourself, push, and re-apply `agent:reviewer`; conflicts in `.github/workflows` always need a person. If the coder fix makes no changes, it automatically asks the reviewer for a fresh review, once per commit. If it makes no changes again, re-applying `agent:coder` would repeat the same result: resolve the remaining findings yourself (or update the issue), then re-apply `agent:reviewer`.

The next queued issue starts automatically as soon as the pipeline is free: after a merge, after the requirements check sends an issue back, or after the coder fails before opening a pull request (that issue leaves the queue; add `status:todo` to retry). Once a pull request exists, its issue keeps the pipeline busy until the pull request merges or closes, even after a failure, so queued issues wait: retry it with the label named in the comment, or close the pull request to free the pipeline. Closing a Squadron pull request without merging removes the issue's status; add `status:todo` to queue it again.

Only pull requests from `squadron/issue-<number>` branches in this repository are automated. Pull requests you open yourself are left alone.

## What agents cannot change

Agents never publish changes under `.github/workflows`. If an issue needs a GitHub Actions workflow (for example CI, releases, or deployments), the coder's requirements check sends it back to its author until the issue either limits the scope to what agents can deliver (scripts, configuration, documentation, or an example workflow stored outside `.github/workflows`) or states that a person will add the workflow. The reviewer does not block a pull request for a missing workflow change; it mentions it as a manual follow-up. Add or change workflow files yourself.
