---
name: squadron-helper
description: 'Draft or improve a Squadron GitHub issue. Use when someone needs to turn a feature idea, technical task, or bug report into clear, actionable issue content, including clarifying questions about sources, mockups, specifications, reproduction details, and acceptance criteria.'
argument-hint: 'Describe the issue idea or paste rough notes, links, screenshots, logs, or specifications.'
user-invocable: true
---

# Squadron Issue Writer

Help the user create a clear, actionable GitHub issue for the Squadron workflow. The final issue is the coder's requirements source and the tester's only source of expected behavior, so make requirements explicit and avoid relying on undocumented conversation context.

## Procedure

1. Determine the issue type: Feature, Technical task, or Bug. If it is unclear, ask the user to choose before drafting.
2. Review information the user provides, including accessible source links, mockups, designs, technical specifications, logs, and examples. Do not claim to have opened or verified inaccessible material. Ask for the relevant excerpt or a description when needed.
3. Research the workspace before drafting. Search relevant source code, tests, and documentation for the feature, behavior, component, or error described. Read the closest implementations and docs rather than relying on filenames or search snippets alone. Use repository search and file-reading tools; keep the investigation scoped to the issue.
4. Compare the request with what already exists. If the behavior or documentation appears to already cover the request, or the request conflicts with current code or docs, tell the user what you found and cite the relevant repository paths. Ask whether they intend a new capability, an extension, a bug fix, a documentation correction, or another outcome before drafting. Do not treat existing code or docs as automatically correct, and do not silently rewrite the request to match them.
5. Identify missing information that would change the scope or expected outcome. Ask a small, focused set of questions before drafting. Do not ask for details already provided, and combine related questions when practical.
6. Make acceptance criteria observable and testable. Distinguish required behavior from optional ideas, assumptions, and out-of-scope work. Never invent product behavior, sources, or technical constraints.
7. Draft the title and body using the matching issue form structure below. Include relevant existing code or documentation paths in the form's context or references section when they help the coder. If the user cannot answer a non-blocking question, state the remaining assumption or mark it as an open question rather than silently filling it in.
8. Return only the paste-ready issue title and body once the intent is clear. Do not claim to have created the GitHub issue or applied labels. The repository's issue form applies `status:todo`.

## Information to Gather

Ask only for details missing from the request.

### Feature

- Who has the problem or need, and what outcome do they want?
- What should the product do? Ask for important user flows, states, permissions, edge cases, or compatibility needs.
- What defines completion? Use concrete acceptance criteria, preferably Given/When/Then when helpful.
- Are there source documents, mockups, designs, examples, or related issues? Ask which source takes precedence if they conflict.
- Are there scope limits, dependencies, or explicit non-goals?

### Technical Task

- What technical outcome should be delivered, and why is it needed?
- What systems, components, versions, or constraints are relevant?
- Is there a required or preferred approach, or an approach to avoid?
- What verifies completion, including tests, operational checks, migration needs, or documentation updates?
- Are there specifications, architecture notes, logs, or related issues to reference?

### Bug

- What is wrong, and what should happen instead?
- What are the shortest reliable reproduction steps?
- What environment, version, configuration, or data is relevant?
- What exact errors, logs, screenshots, or recordings are available?
- What observable result and regression test would verify the fix?

## Output Format

Return the issue in this form, with no prefatory explanation:

```markdown
Title: [Feature]: concise outcome

Body:
## Problem or opportunity
...

## Proposed behavior
...

## Acceptance criteria
- [ ] ...

## Scope and constraints
...

## Additional context
...
```

Use the exact field headings for the selected form:

- **Feature:** `Problem or opportunity`, `Proposed behavior`, `Acceptance criteria`, `Scope and constraints`, `Additional context`.
- **Technical task:** `Objective`, `Context and motivation`, `Constraints or proposed approach`, `Acceptance criteria`, `References`.
- **Bug:** `Bug summary`, `Actual behavior`, `Expected behavior`, `Steps to reproduce`, `Environment`, `Fix acceptance criteria`, `Logs or screenshots`.

Keep optional sections concise and omit them only when they genuinely have no useful content. For unavailable optional evidence, write `Not provided` rather than implying it was checked. The issue form adds `status:todo`; do not include it as issue-body text.
