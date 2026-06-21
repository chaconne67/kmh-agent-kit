---
name: microplan-review-batch
description: Sequentially review multiple microplans with microplan-review, fix review findings, propagate each fix into later microplans, rerun affected reviews, then recheck the full microplan pipeline. Use when the user asks for "microplan-review-batch", "마이크로플랜 리뷰 배치", or wants cascading review of several microplan documents before implementation.
---

# Microplan Review Batch

Review a set of microplans as a pipeline, not as independent documents. Each accepted fix can change the assumptions, order, scope, or completion gates of later microplans, so carry that impact forward before reviewing the next plan.

## Required Inputs

- Microplan documents or a directory containing them.
- The intended order. If the order is not explicit, infer it from filename order and state that assumption.
- The intent/context document used by the microplans. If absent, follow `microplan-review` behavior for missing intent source.

## Core Workflow

1. List the selected microplans in review order.
2. Read the intent/context source and all selected microplans once before editing.
3. Review the first pending microplan with `microplan-review`.
4. If the result is `PASS`, move to the next microplan.
5. If the result is `FIX`, edit that microplan with the smallest wording or gate change that closes the finding.
6. Rerun `microplan-review` on the edited microplan until it returns `PASS`, `ESCALATE`, or a real blocker remains.
7. After every accepted edit, run an impact pass over all later microplans:
   - changed prerequisite or handoff
   - changed scope boundary or non-goal
   - changed data/model/status term
   - changed implementation order
   - changed completion gate or verification command
8. Edit impacted later microplans before reviewing them.
9. Review the next microplan after impact edits are applied.
10. Repeat until the final microplan has a `PASS` result or the batch reaches `ESCALATE`.
11. Recheck the full pipeline from start to finish for cross-plan consistency.
12. Run `code-review-loop` against the selected microplan document set and final diff before reporting completion.

## Domino Rule

Never treat a fixed earlier plan as isolated. Before reviewing plan N+1, compare it against all accepted changes from plans 1..N and update it if its assumptions became stale.

If a later-plan edit changes the meaning of an earlier accepted plan, stop and re-review the earlier plan before continuing. This avoids a circular pipeline where later cleanup silently invalidates earlier closure.

## Escalation

Stop with `ESCALATE` when any single microplan would escalate under `microplan-review`, or when the set cannot be made sequential without changing the master-plan order, domain meaning, security/permission model, irreversible deletion strategy, risky migration strategy, or external API/cost contract.

Do not force a broad redesign inside this skill. Report the first plan and reason that requires Forge or deeper review.

## Editing Rules

- Preserve the user's plan structure and wording style where possible.
- Fix only review blockers and necessary downstream impact.
- Do not add implementation details that belong to `microplan-implement`.
- Do not invent new phases unless required to split an over-scoped microplan.
- Keep each microplan reviewable by the base `microplan-review` limits.
- Preserve unrelated file changes and user edits.

## Pipeline Recheck

After the last plan passes, scan the whole set once more:

- Every handoff from one microplan is consumed by a later microplan or intentionally ends.
- No completion gate contradicts an earlier accepted gate.
- Terms, statuses, filenames, and verification commands are consistent.
- No later plan depends on skipped, unresolved, or escalated work.
- The set still forms an implementable sequence of small closure units.

If the pipeline recheck finds a mismatch, edit the smallest affected document, rerun `microplan-review` for that document, then repeat the pipeline recheck.

## Output Format

Keep the report compact:

```text
결론: PASS | FIXED | ESCALATE

리뷰 순서:
- ...

수정 및 전파:
- plan: 변경 요약 / 영향을 받은 후속 plan

파이프라인 재점검:
- pass/fix/escalate 요약

검증:
- quick checks and code-review-loop result
```

Use `FIXED` when findings were corrected and the final pipeline recheck passed.
