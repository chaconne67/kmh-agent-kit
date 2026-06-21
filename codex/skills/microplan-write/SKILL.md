---
name: microplan-write
description: Write or rewrite a small, implementation-ready micro plan for one selected master-plan phase, todo item, or narrowly scoped coding task. Use only when the user explicitly asks for a micro plan, detailed implementation plan, task plan, or asks to break a specific phase/todo into an implementable unit. Do not use for broad requests like "make a plan", "create a roadmap", "plan this refactor", or "design a feature plan"; those belong to masterplan-write.
---

# Microplan Write

## Trigger Boundary

Use this skill only after a master plan, phase, or specific implementation todo already exists or the user clearly asks for a detailed implementation unit.

Do not use this skill for broad planning requests. If the user asks for an overall plan, roadmap, refactoring plan, new-feature plan, migration plan, or "plan this topic" without selecting a concrete implementation unit, use `masterplan-write` instead.

## Planning Hierarchy

Use this hierarchy when the work has more than one task:

```text
Context
→ what domain world is correct

Master Plan
→ what order closes that world safely

Phase
→ one meaning axis to close

Task
→ the smallest implementable and verifiable unit
```

Do not treat many phases or tasks as a problem when Context and Master Plan are solid. Context is solid when it states intent, reasons, exclusions, and decision boundaries. Master Plan is solid when it states phase order and what each phase closes. This skill starts below that level: it turns one selected phase or todo into the smallest implementable and verifiable unit.

## Preparation Gate

Before writing the plan, run a short preparation pass inspired by Superpowers brainstorming, but keep it microplan-sized.

Answer these questions from the named context, existing docs, and the selected task. Ask the user only when the answer is absent or ambiguous:

- What domain meaning does this task close?
- What is explicitly out of scope?
- What can the next task rely on after this task is complete?
- Which existing code, document, command, or test must be read before implementation?
- Which 1-3 checks prove the task is complete?

If any answer is unclear, resolve it before writing the CRUD table. Do not compensate for unclear intent by adding more implementation tasks.

## Core Shape

Write implementation plans in this order:

1. Domain contract
2. CRUD table
3. Order and dependencies
4. Completion gate

Keep the plan short. For every sentence, ask: "Is this required for implementation or phase handoff?" Remove background, commentary, and nice-to-have detail that does not change what gets built, in what order, or how completion is judged.

Size and scope limits:

- Target 150 lines or fewer.
- Never exceed 180 lines. Split the plan when it would exceed this.
- These limits exist to keep the plan reviewable by `microplan-review` and implementable as one closure unit.
- Include at most 3 leaf implementation tasks in one plan.
- The tasks must share the same meaning axis. If 3 tasks touch different domain meanings, split them.
- Each leaf task must be independently plan-reviewable, implementable, and implementation-reviewable.
- If verification cannot be expressed as 1-3 focused checks, the task is too large.
- Put high-risk work such as deletion, data migration, permission changes, or automatic decision removal in its own small plan when possible.

Closure rule:

- A task is not complete because code changed.
- A task is complete only when the next task can rely on its contract without redefining it.
- Phase-level plans should end with a final leak/check gate when later phases depend on the phase meaning. A leak is old meaning still visible in runtime code, UI text, prompts, commands, tests, or user paths.

## 1. Domain Contract

State what meaning this plan fixes before code changes begin.

Answer:

- What domain concept is being fixed?
- What ambiguity is being removed?
- What must later phases be able to assume without redefining?
- What is explicitly out of scope?

Prefer business meaning over implementation labels. Avoid naming the phase after a specific technical migration unless that migration is the domain purpose.

## 2. CRUD Table

List implementation targets by CRUD impact.

Use a compact table:

| CRUD | Target | Why |
| --- | --- | --- |
| Create | New model, field, service, flow, test fixture, or document artifact | What new capability or contract it creates |
| Read | Audit, query, search, view, report, validation, or discovery point | What existing behavior must be understood or verified |
| Update | Existing model, service, command, UI, prompt, migration, or test | What meaning changes |
| Delete | Legacy model, field, branch, UI, compatibility shim, command, or test assumption | What confusion or obsolete path is removed |

Rules:

- Include only targets that affect implementation order, data preservation, or phase readiness.
- If a target does not change behavior or verification, omit it.
- Separate source/provenance, domain tags, UI labels, status, and workflow state when their meanings differ.

## 3. Order And Dependencies

Explain which CRUD must happen first and why.

Use dependency logic:

- Read before Create when current usage or data shape is uncertain.
- Create before Update when existing data needs a new safe destination.
- Update before Delete when live code still depends on the old structure.
- Delete last when removing old concepts could cause data loss or broken flows.

State blockers plainly. A good order section tells the implementer what is unsafe to do first.

## 4. Completion Gate

Define the conditions for moving to the next phase.

Completion gates should be observable:

- Domain meaning is represented in code.
- Legacy meaning no longer leaks through models, services, UI, prompts, commands, or tests.
- Required data is preserved or intentionally discarded.
- Focused tests or verification commands prove the contract.
- The next phase can rely on the contract without restating it.

Avoid vague gates such as "cleaned up", "improved", or "done". Replace them with conditions that can be checked.

## Frontend And Template Plans

Frontend plans are usually more complex than backend plans because they must close a user path, not just a data or service contract.

For templates, HTMX partials, forms, modals, navigation, or visual workflow changes, write the phase around a user flow or screen meaning, not around a file list.

Add completion gates for:

- What decision or action the user can complete on the screen.
- Which old path is no longer exposed.
- Whether visible wording matches the Context language.
- Whether click, submit, modal, and HTMX response states continue correctly.
- Whether the core action remains usable on narrow/mobile screens when relevant.

Use Playwright, Django client checks, or focused HTML assertions when a backend test cannot prove the user path. Django client or HTML assertions are enough for routing, rendered text, form presence, and permission visibility. Use Playwright for click flows, modals, HTMX swaps, responsive layout, or visual state.

## Writing Style

- Write for implementation, not broad planning or persuasion.
- Prefer tables for scope and short lists for sequence.
- Keep examples local to the current codebase or domain.
- Do not add speculative future features.
- Do not include commit strategy, pull request count, deployment procedure, master-plan phase design, or broad refactoring unless the user asks.
- If the source context contradicts the draft plan, stop and reconcile the domain contract first.
