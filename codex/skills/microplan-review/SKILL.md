---
name: microplan-review
description: Ultra-light review for small implementation plan documents. Use when checking a micro plan, 완료형 구현 계획, phase plan under the microplan-write size limits, or when the user wants a simple plan validation without full Forge/4G adversarial review.
---

# Microplan Review

## Purpose

Validate one small implementation plan without expanding it.

Use this for micro plans that should close one meaning unit. Do not run full adversarial review unless the plan involves irreversible deletion, high-cost migration, security, permissions, external billing/API contracts, or master-plan order decisions.

## Core Rule

Review only the next plan to implement.

Do not review the whole project, do not create a debate log, and do not produce a new agreed document. The output is a short pass/fix verdict.

Before the four checks, identify the intent source:

- If the user names an intent/context document, use that.
- If the plan references a context/spec document, use that.
- If no intent source is clear, ask one short question for the source document.
- If the user wants to proceed without one, review only against the plan's own domain contract and state that limitation.

## Four Checks

Ask only these questions:

1. **Meaning**: Does the plan conflict with the chosen intent source or referenced domain contract?
2. **Scope**: Is it one meaning axis, with at most 3 leaf implementation tasks?
3. **Order**: Does it depend only on completed previous phases, and avoid work that belongs to later phases?
4. **Close**: Are completion gates observable through 1-3 focused checks?

For frontend, template, form, modal, navigation, or HTMX work, apply the Close check to the user path. The gate should prove the relevant screen wording, button/link exposure, form submission, modal state, or HTMX response is correct. If backend tests cannot prove that path, require a focused HTML assertion, Django client check, or Playwright check.

If a concern does not affect one of these four checks, mark it as note or ignore it.

## Severity

Use only three outcomes:

- `PASS`: implement as written.
- `FIX`: a small edit is required before implementation.
- `ESCALATE`: this is not a micro-plan review; use Forge or a deeper review.

Escalate only for irreversible deletion, risky data migration, security/permission changes, external API/cost contracts, unclear domain meaning, or cross-phase order uncertainty.

## Output Format

Keep the answer short:

```text
결론: PASS | FIX | ESCALATE

닫힘을 막는 문제:
- ...

최소 수정:
- ...

구현 전 확인:
- ...
```

Rules:

- Max 5 issues.
- Prefer 1-3 issues.
- Do not invent improvements.
- Do not request broader refactors.
- Do not expand a 50-line plan into an 80-line plan unless closure truly requires it.
- If the plan needs edits, propose the smallest wording or gate change that closes the issue.

## Good Micro Review

```text
결론: FIX

닫힘을 막는 문제:
- 완료 게이트에서 "보류 0건"과 "보류가 있어도 종료 가능"이 충돌합니다.

최소 수정:
- 보류는 후속 phase에 넘기지 않고 별도 조사 task로 분리한다고 한 문장으로 고정합니다.

구현 전 확인:
- 없음.
```

## Bad Micro Review

- Multiple reviewer personas.
- Critical/Major/Minor issue inflation.
- Whole-project critique.
- Rewriting the plan into a large checklist.
- Treating nice-to-have clarity as a blocker.
