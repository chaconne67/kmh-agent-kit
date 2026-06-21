---
name: code-review-loop
description: Use when the user says "코드리뷰반복", "코드 리뷰 반복", "리뷰하고 고쳐", "코드리뷰 스킬 실행 후 수정 후 재리뷰", "code-review-loop", or asks to repeatedly run code review, fix findings, and re-review until no errors or actionable findings remain.
---

# Code Review Loop

## Core Rule

Run a review/fix/re-review loop until there are no high-confidence actionable review findings and focused checks pass, or until a real blocker prevents further progress.

Use the existing `code-review` skill for each review pass when available. If reviewing a GitHub PR, use the GitHub/code-review workflow required by the available skills and tools. If reviewing local changes, review the local diff.

## Loop

1. Run `git status --short`.
2. Identify the review target:
   - GitHub PR if the user provided a PR.
   - Local diff if the user did not provide a PR.
3. Run a code-review pass.
4. If there are no actionable findings, run focused validation and stop when it passes.
5. If there are actionable findings, fix only those findings.
6. Run focused checks for the changed behavior.
7. Run another code-review pass on the updated diff.
8. Repeat until clean.

## Review Pass Rules

- Lead with bugs, behavioral regressions, missing validation, data corruption risks, security issues, deployment hazards, and missing meaningful tests.
- Ignore style-only or speculative issues unless they can cause real failure.
- Keep findings high-confidence and grounded in file/line references.
- Treat failing tests, type errors, syntax errors, and deployment smoke failures as review findings.
- Do not expand scope to unrelated cleanup.

## Fix Rules

- Make the smallest code change that resolves the finding.
- Do not rewrite surrounding code unless the finding cannot be fixed otherwise.
- Do not revert user changes.
- If a finding requires a product decision, stop and ask instead of guessing.
- If the same blocker repeats across three loop attempts, report it as blocked with the exact blocker.

## Validation Rules

- Choose focused checks based on the touched behavior.
- For UI/template/static/common partial changes, perform browser screenshot or equivalent visual validation.
- For DB writes created during debugging, clean up created data and verify zero remaining rows.
- If a check cannot run because of environment or infrastructure, state that clearly and continue only with checks that still provide signal.

## Completion

Finish only when:

- The latest review pass has no actionable findings.
- Focused validation has passed, or any skipped validation has a concrete reason.
- The worktree state is reported.
- Changes are committed when the user requested implementation or the session rules require a commit; otherwise report uncommitted files and why they remain uncommitted.
