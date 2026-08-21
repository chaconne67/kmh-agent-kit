---
name: smart-ux
description: "Use when creating, modifying, or reviewing user interfaces and flows, including screens, components, forms, dashboards, navigation, CTAs, and loading, error, or empty states; or when asked to improve UX, initial loading performance, human task flow, conversion, retention, accessibility, behavioral design, or dark-pattern safety."
---

# Smart UX

Use this skill to turn UI work into behavior-aware product design, not only visual styling. The central rule is: good UX gets people to useful work quickly by loading only what the current task needs, arranging the interface in the order people read and work, lowering friction, clarifying choices, creating honest motivation, and protecting user agency.

## Workflow

Use this sequence while designing, implementing, or reviewing UI, then run the completion checklist after each change.

1. Define one target behavior and the first useful state for the screen.
2. Identify the minimum UI and data needed for that state; defer everything else until the user needs it.
3. Arrange the UI to match the human flow defined below.
4. Implement or review styling against these Tailwind CSS rules:
   - If implementation is requested and the project does not provide Tailwind CSS, stop before UI implementation and report the missing dependency instead of silently using another styling path.
   - Prefer native, non-arbitrary utilities from the installed Tailwind version whenever they can express the required result; do not replace them with custom classes or inline styles.
   - Add a project-specific design token only for a recurring brand or domain meaning; do not create one as an alias for a native Tailwind value or a one-off design choice.
   - Express layout widths as parent-relative Tailwind proportions such as `w-full`, fractional `w-*/*`, flex basis, or grid shares. Use fixed widths, raw CSS percentages, or arbitrary width values only when a concrete requirement cannot be represented proportionally.
5. Map the target behavior to the Hook loop: trigger, action, variable reward, investment.
6. Apply the UX laws that reduce friction and cognitive load.
7. Satisfy the accessibility requirements.
8. Reject dark patterns and keep persuasion honest.
9. Render and visually inspect every affected viewport and interaction state, then verify the completion checklist.

## Loading and Human Flow

- Treat the first useful state as the earliest rendered state that lets the user understand or begin the target behavior. Optimize first for the time to reach that state. Request and render only the elements and data it requires. Defer optional work until the user reaches or requests it; a loading indicator does not justify avoidable initial work.
- Define human flow as the combined reading order, task sequence, and sequence in which data prerequisites are entered, confirmed, or locked. In a left-to-right interface, arrange reading order from top to bottom, then left to right. Follow the interface language's direction when it differs.
- Make the visual sequence match the human flow. Put prerequisites before dependent actions. Place confirmation or locking controls after the values they commit, and place actions that require confirmed or locked data after those controls. Do not arrange controls around implementation convenience.
- Keep DOM order and keyboard focus order aligned with visual order. Do not use CSS reordering to create a conflicting sequence.
- When a positional UX heuristic conflicts with the human flow, preserve the human flow and emphasize the element within its correct step.
- Judge layout from the rendered result. Inspect the affected viewport sizes and changed interaction states in a browser or screenshots. Source inspection and automated tests do not establish visual correctness by themselves.

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
- Miller's Law: Group navigation, tabs, or dense lists into a small number of meaningful chunks that users can scan. Do not force a fixed item limit when the task requires more.
- Tesler's Law: Decide whether the system or the user carries unavoidable complexity. Prefer defaults, inference, and automation when they are accurate.
- Occam / Pragnanz: Remove decorative or duplicate elements that do not help recognition or action.
- Pareto: Put the small set of high-value actions in the strongest locations.

## Interaction

- Fitts's Law: Make frequent or important targets large, close, and easy to reach. Keep touch targets at least 44 by 44 px.
- Doherty Threshold: Remove avoidable initial work first. For latency that remains necessary, show immediate loading, skeleton, progress, or optimistic feedback.
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

- The initial load requests and renders only the elements and data required for the first useful state; deferred work has a clear user or workflow trigger.
- Visual, DOM, and keyboard order all match the human flow.
- The screen has one dominant target behavior and one clearly prioritized primary CTA.
- Choices are chunked or progressively disclosed.
- Main actions are large, close, reachable, and at least 44 by 44 px on touch.
- Loading or latency receives immediate visible feedback.
- Progress, completion, or unfinished state is visible when it motivates completion.
- Success moments provide honest feedback or next value.
- Familiar conventions are preserved unless the product value requires a different pattern.
- Related elements are grouped with clear spacing, alignment, and hierarchy.
- Styling uses Tailwind CSS, and native non-arbitrary utilities replace custom classes and inline styles wherever they can express the same result.
- Project-specific design tokens exist only for recurring brand or domain meanings that native Tailwind values cannot represent; no token merely aliases a native value or a one-off choice.
- Layout widths use parent-relative Tailwind proportions; every fixed, raw CSS percentage, or arbitrary width has a concrete requirement that proportional utilities cannot satisfy.
- Errors and empty states explain the next action without blaming the user.
- The rendered UI was visually inspected at every affected viewport and changed interaction state; source inspection or automated tests were not used as a substitute.
- Accessibility requirements above are satisfied.
- No dark pattern is present.
