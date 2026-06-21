---
name: masterplan-write
description: Write or rewrite a broad master plan, roadmap, or phase plan for a topic before detailed microplans exist. Use when the user asks to "make a plan", "create a roadmap", "plan this refactor", "plan this feature", "마스터 플랜", "계획 세워봐", or gives a large development/refactoring/research/decision topic and wants the overall order of work. Do not use for a selected implementation unit or detailed coding task; use microplan-write for that.
---

# Masterplan Write

## Purpose

Create the plan that sits above micro plans. A master plan explains why the work matters, what kinds of work are needed, which work needs code, and what order lets later micro plans proceed safely.

A master plan must be based on shared intent, not agent guesses. Before drafting, remove ambiguity that would change scope, order, ownership, production risk, or success criteria.

## Boundary

Use this skill for broad planning. The output is not an implementation task document.

Do not write CRUD tables, exact test commands, file-by-file edits, or 150-line microplan-style closure gates unless the user explicitly asks. Put implementation candidates into phase-level todos that `microplan-write` can later expand.

If the user has already selected one phase or one implementation todo and asks for detailed implementation steps, use `microplan-write` instead.

## Intent Alignment Gate

Before writing the master plan, identify unresolved intent questions.

Do not draft the master plan while any high-impact ambiguity remains. High-impact ambiguity includes unclear goal, target users, affected systems, runtime ownership, data preservation, production actions, external services, permissions, cost, irreversible changes, or success criteria.

Use the `grill-with-docs` questioning pattern:

- Ask questions one at a time and wait for the user's answer before continuing.
- For each question, explain what decision it controls.
- Provide a recommended answer or default assumption with the question.
- If a question can be answered by inspecting code, docs, `CONTEXT.md`, ADRs, config, scripts, or existing plans, inspect those instead of asking.
- If the user's wording conflicts with existing project language or code behavior, surface the conflict and ask which meaning should win.
- When a fuzzy term controls the plan, propose one precise term and ask the user to accept or correct it.
- Use concrete scenarios when boundaries are unclear.

Proceed to the master plan only when one of these is true:

- The user has answered all high-impact questions.
- Local evidence answers the question.
- The ambiguity is low-impact and can be recorded as an explicit assumption under "Decisions and unknowns".

## Output Format Gate

Before drafting the master plan, ask which document format the user wants unless the user already specified it.

Use one short question:

```text
마스터 플랜을 어떤 형식으로 작성할까요? Markdown 문서로 작성할까요, 아니면 HTML 검토 문서로 작성할까요?
```

Default recommendation:

- Use Markdown for ordinary strategy, backend, data, operations, migration, or architecture plans.
- Use HTML when the plan must also serve as a visual/UI/UX review artifact or when the user wants to inspect screens in a browser.

If the user chooses HTML, use the `html-plan-writing` skill before drafting. `masterplan-write` owns the plan's purpose, scope, order, decisions, phases, and validation; `html-plan-writing` owns the HTML document structure, UI/UX preview boundaries, scenario controls, mobile preview, and separation between user-facing UI and implementation notes.

## Required Output Shape

For Markdown master plans, write the master plan in this order:

1. Purpose and intent
2. Work needed to reach the purpose
3. Decisions and unknowns
4. Code implementation phases
5. Validation and handoff
6. Next question to the user

For HTML master plans, include the same master-plan content inside the structure required by `html-plan-writing`:

1. Title and purpose
2. Actual implementation preview
3. Scenario controls or sample states, if relevant
4. Implementation notes
5. Decisions and unknowns
6. Code implementation phases
7. Validation and handoff
8. Next question to the user

## 1. Purpose And Intent

State the user's topic in business or product meaning first.

Answer:

- What problem or opportunity is being addressed?
- Why does this work matter to the user?
- What should be true when the plan succeeds?
- What is out of scope for this master plan?

Prefer user-facing meaning over implementation labels. If intent is ambiguous, ask one short clarification before writing detailed phases.
For high-impact ambiguity, use the Intent Alignment Gate instead of a single clarification.

## 2. Work Needed

List the work types needed to reach the purpose. Include only work that affects the plan's order or readiness.

Common work types:

- Current code or document review
- Domain or data investigation
- User or product decision
- External research
- Design or flow decision
- Code implementation
- Migration or data preservation
- Verification
- Documentation

For each item, state what must be learned, decided, built, or checked. Do not turn every item into a coding task.

## 3. Decisions And Unknowns

Separate work that Codex can do from choices the user must make.

Use this distinction:

- Codex can inspect local code, compare documents, draft options, and implement approved code.
- The user must decide product direction, external commitments, credentials, production actions, cost-bearing actions, and business trade-offs when the answer is not already in context.

## 4. Code Implementation Phases

Create a separate section for code-writing work only.

Use ordered phases:

```text
Phase 1: ...
- Todo: ...
- Todo: ...

Phase 2: ...
- Todo: ...
```

Rules:

- Each phase should represent one meaningful implementation step, not a file list.
- Todos should say what needs to be done, not how every line should be changed.
- Put prerequisite investigation or decisions before the coding phase that depends on them.
- If a phase is too broad for one micro plan, say that it should be split before `microplan-write` receives it.
- Mark high-risk work such as deletion, data migration, permission changes, or external API changes as separate phases.

## 5. Master Plan Self-Check

Before finalizing, apply the same checks used by `check-master-plan`:

- Meaning fit: phases preserve the stated purpose.
- Order fit: earlier phases make later phases safer.
- Boundary fit: master plan does not contain microplan-level detail.
- Verb precision: vague verbs like remove, migrate, replace, clean up, align, delete, or Korean equivalents distinguish physical deletion, runtime disuse, data movement, logic removal, or semantic reinterpretation.

When this skill's own instructions are edited, review the wording with `skill-writing-guide`: keep behavior-changing rules, remove obvious explanation, and make trigger boundaries explicit.

## 6. Final Question

End by asking whether the user wants to continue into micro planning.

Use a concrete question:

```text
이어서 어떤 Phase의 마이크로 플랜을 작성할까요?
```

If one phase is clearly the safest next step, recommend it briefly before asking.
