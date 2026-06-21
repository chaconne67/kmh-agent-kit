---
name: microplan-verify
description: Verify an implementation against one or more microplan/context documents, then fix concrete mismatches and rerun focused checks. Use when the user asks for "microplan-verify", "구현 검증", "계획대로 됐는지 점검", or when microplan-implement or microplan-batch needs post-implementation verification against planner intent.
---

# Microplan Verify

Implementation verification against planner intent. Treat the plan/context documents as the intended behavior, but keep engineering judgment: if the plan is stale and tests/code reveal a safer interpretation, report it instead of blindly forcing the text.

## Inputs

- Implementation plan document(s): required.
- Planner-intent context document(s): strongly preferred. Ask for them when absent, for example `CONTEXT.md`, ADRs, domain notes, or product specs.
- Changed files or current diff: discover with `git status --short`, `git diff`, and plan file paths.

## Workflow

1. Read the plan and context documents.
2. Extract a checklist of intended behavior:
   - files or modules expected to change
   - user-visible behavior
   - data migrations or persistence effects
   - tests and verification commands
   - explicit non-goals
3. Compare implementation to the checklist.
4. Run focused verification:
   - commands named in the plan first
   - then the narrowest related tests/lint/checks
   - if a command cannot run, record why
5. Classify findings:
   - `FAIL`: implementation contradicts intent or tests prove breakage
   - `REVIEW`: plan and code disagree, but code may be intentionally better or the plan appears stale
   - `PASS`: behavior matches intent well enough
6. Fix `FAIL` items directly when the current user request or calling skill authorizes implementation changes.
7. Rerun focused checks after fixes. Stop when all items are `PASS` or only `REVIEW` remains.

## Verification Rules

- Prefer meaning over literal wording. A renamed helper is fine; lost behavior is not.
- A `PASS` result requires fresh evidence from this verification run: command, exit status, and observed result.
- Do not reuse earlier test output or infer success from code inspection when a runnable check exists.
- Preserve user changes and unrelated dirty worktree changes.
- Keep fixes inside the plan's intended scope unless a test proves a nearby correction is required.
- Do not add backwards-compatibility shims or defensive branches unless the plan requires them.
- For migrations, verify fresh-replay safety: migration code must not depend on runtime helpers that may change later.
- For tests, missing coverage is `FAIL` only when the plan explicitly required it or the change is risky enough that untested behavior is likely to regress.

## Output

Report in this shape:

```text
구현 검증 결과: PASS | FAIL | REVIEW

FAIL
- path:line — 의미상 문제와 수정 여부

REVIEW
- path:line — 사용자 판단이 필요한 계획/코드 불일치

검증
- command — pass/fail/not run
```
