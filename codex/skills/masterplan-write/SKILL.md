---
name: masterplan-write
description: Write and internally review implementation master plans before microplans. Use for master plans, roadmaps, phase plans, broad implementation plans, "마스터 플랜", or "계획 세워봐". Produces phase maps for later microplan-write, but does not write microplans without user approval.
---

# Masterplan Write

## Core Rule

A master plan is not a document-writing task. A master plan is the top-level implementation plan that defines the phase artifacts later microplan-write will create.

Master plan completion includes internal review. Do not finish after drafting only. Draft the master plan, attempt an independent subagent review using the review rubric below, apply concrete findings, then deliver the reviewed plan. If no subagent tool is available in the current environment or the subagent call fails, perform the same rubric yourself and state that the independent pass could not run.

Do not create a separate intent document before the master plan unless the user explicitly asks for one. Put a short intent summary inside the master plan, then move directly into implementation strategy and phased implementation order.

If the request came from a proposed method, architecture, research result, or reusable pattern, the master plan must explain how that method will be implemented in the target system. Do not replace implementation with a "baseline document", "decision document", "contract document", or "research artifact" unless that artifact directly unlocks a named implementation phase and is not reported as the implementation itself.

## Before Drafting

Resolve only ambiguities that would change implementation scope, data ownership, production risk, irreversible changes, or success criteria.

Inspect local code, current planning-authority sources, GBrain, ADRs, configs, and prior plans before asking the user. Ask only when local evidence cannot answer a high-impact choice.

When the project has a GBrain planning authority index, read it before broad planning and use its named canonical page as the current source. Treat `local-docs/*`, deleted local planning docs, old master plans, and old microplans as historical references unless the canonical page explicitly promotes them.

If the user asks for a durable plan in a topic governed by a canonical GBrain page, update or create that canonical page instead of creating a competing local plan file. Use a local file only when the user explicitly asks for a file artifact or a downstream tool requires a temporary artifact.

When durable plans live in GBrain, manage the work as one topic planning package:

- Search GBrain for the same topic before writing. Reuse the existing package when one exists; create a new package only when no current same-topic package exists.
- Use one stable package root slug for the topic. The root page is the package index and current-state page.
- Store or update the reviewed master plan at `{package-root}/master-plan`.
- Record the package root, master-plan slug, current priority, superseded prior plan slugs, and microplan artifact candidates on the root page.
- For a newer version of the same topic, update the stable package in place and move replaced decisions to Superseded History instead of creating a competing package.
- Add or update the planning authority index when a package becomes the current authority for its topic.

Master plan completion in a GBrain-authoritative project requires the reviewed master plan to be written to `{package-root}/master-plan` and the package root to be updated. If direct GBrain write access is unavailable, stop before presenting the plan as completed and report the exact package root, master-plan slug, master-plan content, root update, and planning-authority index update that must be written.

For low-impact unknowns, state an assumption inside the plan and keep going.

Do not ask the user whether the plan should be Markdown or HTML unless they explicitly need a browser-review artifact. Use Markdown by default; the file format is only a container, not the goal.

## Required Master Plan Shape

The generated master plan must use exactly these three top-level sections, in this order.

## 1. Intent

Summarize the user's goal in product or business terms.

Include:

- what problem or opportunity the work addresses
- what must be true when implementation succeeds
- what is out of scope
- any high-impact assumptions or user decisions still open

Keep this section short. Do not turn it into a separate requirements document.

## 2. Implementation Approach

Explain the concrete implementation approach.

Include:

- target runtime path, module, service, model, API, UI, job, or data flow
- current behavior or baseline that will be changed
- proposed architecture or algorithm
- how existing code will be reused or replaced
- data contracts, persistence, migrations, external services, or permission boundaries if relevant
- failure handling and observability that affect implementation
- validation strategy tied to user-visible behavior

When the user asks to apply a methodology, name the actual code path where that methodology enters the system. For example, "embedding lane joins ranking in `parse_and_search()` after hard filters" is valid; "write an embedding plan" is not.

## 3. Microplan Phase Map

Break the implementation into ordered phases that will become later microplan artifacts if the user approves microplan-write.

Each phase must include:

- microplan artifact candidate title
- phase objective
- microplan scope
- out-of-scope work
- dependency on previous phases

Keep phase entries compact. The master plan defines the sequence and scope boundaries; microplan-write will later expand the approved phase map into separate microplan artifacts unless the user explicitly selects a single phase.

Use this shape:

```text
Phase 1: <microplan artifact candidate title>
- Objective: <what this phase accomplishes>
- Microplan scope: <what a later microplan should cover>
- Exclude: <what that microplan should not cover>
- Depends on: <previous phase or "none">
```

Rules:

- Every phase must be implementable or verification-enabling.
- Documentation may appear inside a phase only as support for implementation or handoff.
- Do not count documentation-only work as a completed implementation phase.
- Do not over-specify phase internals; leave detailed CRUD/order/completion gates to microplan-write.
- Put risky migration, deletion, production, external API, and permission work in separate phases.
- If one phase is too broad for one microplan artifact, split it into multiple phases now.
- Do not run microplan-write automatically. The user chooses whether and when to start microplan writing.

End section 3 with the approved microplan artifact candidates:

```text
Microplan artifact candidates:
1. task-001 - Phase 1 - <title>
2. task-002 - Phase 2 - <title>
...
```

## Internal Master Plan Review

After drafting and before final response, review the master plan. Attempt an independent subagent review whenever a subagent tool is available in the current environment. Give the subagent the draft artifact and this rubric, not your private diagnosis.

Review rubric:

- Implementation viability: phases point to real code/data/runtime surfaces and can lead to implementation.
- Scope control: the plan does not turn into a research artifact, baseline document, or microplan-level detail dump.
- Phase map quality: each phase is a later microplan artifact candidate with clear scope, exclusions, and dependencies.
- Authority fit: the plan uses the current canonical source when one exists and does not treat historical local-doc mirrors as current planning authority.
- Dependency order: later phases do not require unbuilt behavior from future phases.
- Verification adequacy: the plan names user-visible or runtime validation responsibilities without expanding them into full microplan gates.
- Existing-system fit: the plan respects current project architecture and prior plans.
- Risk isolation: migrations, destructive work, external APIs, production actions, and permission changes are isolated.

Apply concrete review findings before presenting the plan. If a finding is a product decision rather than a plan defect, keep it in the plan as an open user decision.

Do not tell the user to run a separate master-plan check after writing the master plan. This skill owns the master-plan review step and must not require a second user command for ordinary master plan creation.

Do not use the older per-phase Build/Touch/Verify/Depends shape for new master plans unless the user explicitly asks for a detailed implementation plan. That detail belongs in a later microplan.

In the final response, briefly report whether the review used a subagent or a manual rubric pass, and summarize any concrete findings that changed the plan.

## Self-Check

Before finalizing, verify:

- The plan would lead to code/data implementation, not just documents.
- The three top-level sections are present and no extra top-level sections were added.
- Each phase has a concrete implementation outcome.
- Each phase is a microplan artifact candidate with objective, scope, exclusions, and dependency.
- No phase contains microplan-level CRUD/order/completion-gate detail unless explicitly requested.
- Internal master-plan review attempted a subagent pass when the tool was available, or the same rubric was applied manually after a concrete unavailability/failure condition.
- The final plan does not ask the user to run a separate master-plan check.
- The final plan does not automatically start microplan-write; it leaves microplan artifact creation for user approval.
- The final response reports the review method and any plan changes from review.
- The plan preserves the user's original method or intent instead of narrowing it silently.
- Vague verbs such as align, clean up, migrate, replace, remove, or Korean equivalents state the concrete runtime action.

When editing this skill, use `skill-writing-guide` and keep only behavior-changing rules.
