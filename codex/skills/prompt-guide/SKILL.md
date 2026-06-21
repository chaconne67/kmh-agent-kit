---
name: prompt-guide
description: "Design or review prompts and instruction texts that an LLM reads to decide what to do, including runtime prompts, agent instructions, skill instructions, prompt templates, and reusable task directives. Apply three prompt golden rules: avoid hardcoding, provide enough context, and use optimized examples. Do not use for domain correctness, code bugs, implementation-plan validation, architecture decisions, policy authority changes, or casual one-off instructions unless the user explicitly asks to review the instruction wording."
---

# Prompt Guide

Use this skill when writing or reviewing text whose job is to guide LLM behavior.

## Do Not Use For

Do not use this skill when the real question is not prompt or instruction quality.

- Code bugs, failing tests, runtime errors, data model defects, or architecture decisions.
- Domain correctness, business policy, legal/medical/financial truth, or product decisions.
- Implementation-plan validation, phase order, completion gates, or context-to-plan alignment.
- Permission hierarchy, safety policy, tool authority, or system/developer instruction precedence.
- Casual one-off user instructions unless the user explicitly asks to review the wording.

If the request mainly belongs to one of these categories, stop and use the appropriate skill or ordinary reasoning. You may still use this skill for the wording layer after the non-prompt question is settled.

## Review Output

For each issue, report:

- Original wording
- Violated golden rule or anti-pattern
- Why it fails and expected failure mode
- Improvement direction

Do not mention parts that are already fine. Prefer catching a real prompt risk over staying silent, but mark uncertain issues as uncertain.

## Three Golden Rules

### 1. Avoid Hardcoding

Do not turn one failed case into a narrow rule. Prefer the principle that explains why the case failed.

Hardcoding signs:

- Enumerating many exact values where unseen variants will appear.
- Adding repeated "do not" patches after tests fail.
- Branching as "if A then X, if B then Y" when future C-like cases are likely.
- Using fixed thresholds as judgment when input complexity varies.

Not hardcoding:

- Output schemas, date formats, enum names, and required field names are specifications.
- Domain facts are context when they explain the task.

### 2. Provide Enough Context

The model needs the reason behind instructions, not only the instruction text.

Include the missing context that affects judgment:

- Output purpose: who or what consumes the result.
- Reason: why the instruction exists.
- Failure cost: whether false positives or false negatives are worse.
- Input properties: quality, shape, ambiguity, and expected variance.

Warning signs:

- MUST, NEVER, "always", or "절대" appears without a reason.
- A prohibition has no "instead do this" behavior.
- The prompt specifies a format but not how empty, partial, or ambiguous input should be handled.

### 3. Use Optimized Examples

Use examples only when a principle is still ambiguous. Examples should clarify boundaries, not become a new hidden test set.

Good examples:

- Show both included and excluded cases.
- Explain the reason for the classification.
- Use generalized patterns rather than one-off test cases.
- Match the domain where the prompt will run.

Warning signs:

- Only positive examples are shown.
- Many examples repeat the same pattern.
- A specific test failure is pasted as the canonical example.
- Examples remain after the principle is already clear.

## Anti-Patterns

- Test failure to rule patch loop: every failure adds another narrow prohibition.
- Verbosity as effort: repeated wording, emotional emphasis, or background that does not change output.
- Information loss then recovery: one step discards data and a later step tries to infer it again.
- Single placement of a core instruction: in a long prompt, a key rule appears only once and is diluted.
- Term ambiguity: generic words like result, data, item, content, or target refer to different objects.
- Context pollution: logs, prior failures, or another step's reasoning leak into the current step's judgment.

## Checklist

Use this checklist as diagnostic lenses, not as automatic prescriptions:

- Are three or more exception rules covering the same underlying failure?
- Does each prohibition explain the reason and replacement behavior?
- Is the false-positive versus false-negative cost stated where classification matters?
- Do examples form boundary pairs with reasons?
- Are measurable thresholds justified by the task rather than copied from a test?
- Do action instructions name the actor, object, and concrete verb?
- Does the same generic noun refer to multiple things?
- Does the same thing have multiple names?
- Can any sentence be removed without changing output behavior?
- Are roles, input ranges, and output responsibilities separated in multi-step prompts?
- Are preservation and discard rules explicit when normalizing data?
- In prompts over about 500 tokens, is the core instruction reinforced through framing, checking, or output validation instead of copied verbatim?

## Self-Check Before Reporting

Before finalizing a review or rewrite, verify:

- The suggested change preserves the prompt's core purpose.
- The change does not fight the workflow's actual dynamics, such as adversarial review, iterative refinement, or self-correction.
- The failure-cost direction still holds in this workflow.
- The fix does not add a narrower hardcoded rule than the original.
