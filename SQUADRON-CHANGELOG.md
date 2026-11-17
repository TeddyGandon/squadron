# Squadron Changelog

## 2026-11-17

- Fixed a loop where the reviewer asked for a GitHub Actions workflow change that agents are not allowed to make, so the coder fix failed with no changes. The requirements check now returns issues that need workflow files to `status:todo` unless that part is marked out of scope or manual, and the reviewer reports missing workflow changes as a manual follow-up instead of a blocking finding.
- The requirements helper skill now warns when an issue needs a workflow file and helps scope it accordingly.

## 2026-11-15

- The **Squadron Update** workflow now updates itself first: if its own file changed in the template, it commits the new version and relaunches itself to finish the update.
- The update now copies an explicit list of template files instead of replacing the whole `.github/` directory, so your own `.github/` files are kept. It also commits `SQUADRON-CHANGELOG.md`, which was copied but not committed before.
- Added the manual **Squadron Update** workflow to sync the template's `.github/`, `SQUADRON.md`, and `USAGE.md` into product repositories and commit changes as `chore: update Squadron`.
- Documented the update process and its overwrite behavior; updated setup guidance for the token's Workflows permission.
- Added a changelog to understand the updates.

## 2026-11-14

- Added a requirements check before implementation. The checker identifies missing or ambiguous issue requirements, reports questions, and returns the issue to the ready state instead of starting implementation prematurely.
- Added the requirements-checker skill and report extraction helper, and updated the workflow and documentation to describe the behavior.

## 2026-11-12

- Improved the role workflows and their handoffs, including shared label handling, dependency installation, setup checks, and clearer reporting.
- Added helper scripts and refreshed the workflow and template documentation.

## 2026-11-10

- Added a skill to help users write actionable issues.
- Expanded test-file matching to cover supported test files throughout the repository and centralized the test command and path configuration.
- Simplified the role workflows and updated their documentation.

## 2026-11-02

- Improved tester dependency installation, test command handling, and reviewer/coder label transitions.
- Switched issue processing to use `status:todo` as the coder trigger.
- Updated the README and usage guidance.

## 2026-11-01

- Established the initial GitHub Actions workflow for issue-driven coding, review, and testing, with Feature, Technical task, and Bug issue forms.
- Added workflow setup and documentation, plus the Squadron logo and project branding.
- Improved workflow reliability with token-permission checks, reviewer response validation, safer report extraction, and tester handling for unmatched test paths.
- Updated successful tester runs to squash-merge pull requests and refined the workflow guidance.
