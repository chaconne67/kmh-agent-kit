---
name: smart-ux
description: "Use when creating or modifying UI/UX code, screens, components, flows, landing pages, forms, dashboards, onboarding, notifications, navigation, CTAs, loading/error/empty states, or when asked to improve UX, conversion, retention, accessibility, behavioral design, or dark-pattern safety. UI/UX 생성·수정 직전과 직후에 Hook model, UX laws, accessibility checks, and ethical persuasion guardrails를 적용한다."
---

# Smart UX

Use this skill to turn UI work into behavior-aware product design, not only visual styling. The central rule is: good UX changes behavior by lowering friction, clarifying choices, creating honest motivation, and protecting user agency.

## Workflow

Run this sequence before changing UI code and repeat the checklist after changing it.

1. Define one target behavior for the screen.
2. Map that behavior to the Hook loop: trigger, action, variable reward, investment.
3. Apply the UX laws that reduce friction and cognitive load.
4. Satisfy the accessibility requirements.
5. Reject dark patterns and keep persuasion honest.
6. Verify the final UI with the completion checklist.

## Hook Loop

Design core screens so one useful loop can complete.

| Step | Meaning | UI obligation |
| --- | --- | --- |
| Trigger | Signal that starts the action | Provide one clear CTA, empty-state next step, or notification entry point. |
| Action | Smallest useful action | Reduce clicks and fields. Use defaults and autocomplete when they reflect real user intent. |
| Variable reward | Positive feedback with some freshness | Show completion feedback, progress, new value, or light celebration without manipulating the user. |
| Investment | User effort that increases future value | Make saved settings, profiles, lists, follows, drafts, or preferences visibly accumulate. |

Use variable reward only when it reflects real value. Do not use it to create compulsion, hide costs, or make escape harder.

## Decision Load

- Hick's Law: Reduce simultaneous choices. Group options and use progressive disclosure.
- Miller's Law: Keep navigation, tabs, or dense lists in 5-7 meaningful chunks when possible.
- Tesler's Law: Decide whether the system or the user carries unavoidable complexity. Prefer defaults, inference, and automation when they are accurate.
- Occam / Pragnanz: Remove decorative or duplicate elements that do not help recognition or action.
- Pareto: Put the small set of high-value actions in the strongest locations.

## Interaction

- Fitts's Law: Make frequent or important targets large, close, and easy to reach. Keep touch targets at least 44 by 44 px.
- Doherty Threshold: Preserve perceived responsiveness. For slower work, show immediate loading, skeleton, progress, or optimistic feedback.
- Goal Gradient / Zeigarnik: Use steps, progress, completion percentage, or visible unfinished state when completion matters.
- Serial Position Effect: Place the most important list or nav items where users remember them: first or last.
- Von Restorff: Make one primary action stand out. Avoid multiple competing CTAs.
- Peak-End Rule: Design success, error, and exit moments carefully because they shape the remembered experience.

## Familiarity

- Jakob's Law: Prefer conventions users already know, such as expected navigation, cart, search, save, and home patterns.
- Gestalt grouping: Put related elements near each other, inside a shared region, or under a shared label.
- Similarity: Use consistent shape, color, and placement for the same action or state.
- Postel's Law: Accept flexible input formats when safe. Give strict, clear output and avoid blaming the user for errors.

## Accessibility

Treat these as completion requirements.

- Use semantic HTML: `button`, `nav`, `main`, headings, labels, and native controls where possible.
- Ensure keyboard access: Tab order, Enter/Space activation, and no keyboard traps.
- Keep visible `:focus-visible` styles.
- Give every input and icon button an accessible name.
- Meet contrast: 4.5:1 for body text and 3:1 for large text.
- Keep touch targets at least 44 by 44 px with usable spacing.
- Respect `prefers-reduced-motion`; avoid unavoidable autoplay or excessive motion.
- Use ARIA only when native semantics are insufficient.
- Announce loading, error, and empty states when screen-reader users need the state change.

## Ethical Guardrails

Never implement these patterns. Offer a transparent alternative when requested.

- Hiding or complicating cancellation, deletion, opt-out, unsubscribe, or account closure.
- Charging after a trial without clear prior consent and visible cancellation.
- Guilt-based copy such as manipulative refusal labels.
- Fake urgency, fake scarcity, fake countdowns, or fake social proof.
- Pre-checked consent or extra-charge boxes.
- Misleading button color, placement, or wording that induces mistaken clicks.
- Infinite scroll, autoplay, or reward loops without escape, pause, or control.

Use good friction when it protects the user: destructive-action confirmation, payment summary, undo windows, and review steps for irreversible changes.

## Completion Checklist

Before reporting a UI task complete, verify each item and fix misses in the same final path.

- The screen has one dominant target behavior and one clearly prioritized primary CTA.
- Choices are chunked or progressively disclosed.
- Main actions are large, close, reachable, and at least 44 by 44 px on touch.
- Loading or latency receives immediate visible feedback.
- Progress, completion, or unfinished state is visible when it motivates completion.
- Success moments provide honest feedback or next value.
- Familiar conventions are preserved unless the product value requires a different pattern.
- Related elements are grouped with clear spacing, alignment, and hierarchy.
- Errors and empty states explain the next action without blaming the user.
- Accessibility requirements above are satisfied.
- No dark pattern is present.

## Source Basis

Sources: "The UX Psychology Behind Apps People Can't Stop Using", Laws of UX, the Hook Model, accessibility rules, and ethical AI/product UX guardrails. A Claude Code copy of this skill lives at `~/.claude/skills/smart-ux/`.
