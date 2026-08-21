---
name: smart-ux
description: "Use when designing, implementing, or reviewing user interfaces, user flows, interaction states, loading performance, accessibility, or ethical UX."
---

# Smart UX

Build UI so people reach useful work quickly, understand the screen in the order they read and act, and see a visual system whose emphasis matches function. Protect loading speed, accessibility, and user agency as product requirements rather than finishing touches.

## Workflow

Use this single path for UI design, implementation, and review.

1. Define the screen's target outcome and whether it is an action, reading, or monitoring screen.
2. Define the first useful state and the minimum critical UI, data, and assets required to reach it.
3. Trace each required datum from its UI consumer through the project's actual delivery path to its authoritative producer, then classify it as initial or deferred. Inspect only the layers that exist in the chosen architecture, such as request or render handlers, data-access or service calls, render context or serialized responses, and client state.
4. Inspect the existing component, theme, spacing, typography, and interaction sources before choosing visual rules.
5. Arrange information, prerequisites, controls, and results in the human and data flow defined below.
6. Implement or review styling through the Tailwind path defined below.
7. Apply the interaction, accessibility, and ethical rules.
8. Render and inspect every affected viewport and interaction state, inspect the real data-delivery path, then run the completion gate.

## First Useful State, Data Delivery, and Loading

- Make time to the first useful state the first implementation priority. This state is the earliest rendered UI that lets the user understand or begin the target outcome.
- Request and render only the critical UI, data, and assets for that state. Start independent critical requests in parallel, but request dependent data only after its prerequisites are known.
- Keep the initial data delivery to the access-checked fields, rows, ranges, and relationships required for that state. Do not load a complete history or related collection when the initial UI uses only a summary or selection.
- Lazy-load every non-critical data set, client module, and media asset from a clear viewport, interaction, or workflow trigger. Load critical above-the-fold and LCP resources early; do not delay them behind lazy loading.
- Reuse the project's existing data-delivery path when it can enforce the required contract cleanly. Add a delivery path only when the existing path cannot separate initial and deferred work without weakening clarity, validation, or authorization.
- Define each deferred delivery's trigger, prerequisites, inputs, output shape, authorization, validation, range or pagination, and loading, error, and empty states.
- Give each data-affecting default one authoritative owner. When a default changes data scope, access, or domain meaning, let the domain or data producer own it and expose it to consumers; do not redefine it in the template or client. Keep purely presentational defaults in the presentation layer.
- Use an available implementation or project skill alongside this skill when UI work changes a data producer, data-access operation, authorization rule, serialization step, or delivery contract. Use Smart UX to define the first-useful-state and data-flow contract, and use the companion skill to verify correctness in the project's framework and runtime.
- Do not render empty result cards or decorative placeholders before they carry meaning. For unavoidable latency, reserve stable space and show immediate loading or progress feedback.
- A spinner or skeleton does not justify avoidable initial work. Verify the real data and render path instead of assuming source-level deferral improved loading.

## Layout and Human Flow

- Human flow combines reading order, task order, and data dependency order. Arrange it from top to bottom and then in the interface language's reading direction.
- Keep visual, DOM, and keyboard focus order aligned. Do not use CSS reordering to create a conflicting sequence.
- Align headings, descriptions, fields, content, and actions to shared edges. Reuse the existing spacing scale so gaps express hierarchy instead of one-off decoration.
- Make the page purpose, current state, required input, main content, and next outcome distinguishable through typography, spacing, and placement.
- Put prerequisite inputs before the values or actions that depend on them. Place review or confirmation after the values it commits, and expose dependent actions only when their prerequisites are valid.
- Group related content with proximity, whitespace, alignment, or dividers first. Use a card or box only when it communicates a real structural, state, or interaction boundary; avoid nested containers that add no meaning.
- Make visual emphasis follow functional importance, status, and action availability. Preserve this logical progression across responsive layouts without dropping context or moving focus order away from visual order.

## Visual System and Components

- Reuse existing components and their established visual contracts before inventing a new treatment. Do not replace a project source of truth with a generic palette, size, radius, or shadow.
- When no suitable source exists, define the smallest consistent component family with Tailwind utilities. Comparable controls should share typography, spacing, sizing, shape, border, state, and focus treatment.
- Choose button treatment from action meaning and readability within the existing visual system: primary, secondary, low-priority, or destructive. Use labels, hierarchy, placement, and shape as well as color to communicate meaning.
- Show one primary CTA only when the current step has one primary action. Reading and monitoring screens do not need a CTA; keep destructive actions visually distinct and separate from routine actions.
- Keep forms consistent in label, input, help, validation, and error order. Connect each message to its field and explain how to recover.
- Give modals a clear title, purpose, impact, and action order. Provide a clear close or cancel path, keep focus within the open modal, and return focus to the invoker when closed.

## Tailwind Implementation

- If implementation is requested and the project does not provide Tailwind CSS, stop before UI implementation and report the missing dependency instead of silently using another styling path.
- Reuse existing Tailwind components and theme values whose contracts match the task. Preserve component behavior while replacing avoidable custom visual CSS with native utilities in the affected path.
- Prefer native, non-arbitrary utilities from the installed Tailwind version whenever they express the required result. Do not replace them with inline styles or page-specific classes.
- Add a project-specific design token only for a recurring brand or domain meaning. Do not create a token as an alias for a native Tailwind value or a one-off design choice.
- Express layout allocation with parent-relative Tailwind utilities such as `w-full`, fractional widths, flex basis, or grid shares. Use Tailwind max-width or fixed-size utilities only for intrinsic controls, readable line length, accessibility, or an explicit external constraint.
- Use arbitrary values or custom CSS only when existing components, theme values, and native utilities cannot express a concrete requirement. State that requirement before adding the exception.

## Interaction and Feedback

- Reduce simultaneous choices, group related options, and progressively disclose secondary work. Prefer familiar patterns unless a product requirement justifies a different interaction.
- Provide immediate visible feedback for latency. Use optimistic state only when failure is reversible and the UI reconciles with the authoritative data state; otherwise show pending progress until confirmation.
- Show progress for meaningful multi-step work. Make success, error, empty, and exit states explain the current result and the next available action without blaming the user.
- Apply the Hook loop only to a repeatable behavior that creates real user value: a clear trigger, the smallest useful action, an honest result or reward, and an investment that improves future value. Skip reward or investment for one-off, reading, monitoring, destructive, compliance, and administrative flows.

## Accessibility

Treat the applicable product accessibility contract as a completion requirement and meet WCAG 2.2 AA at minimum.

- Use semantic HTML and native controls. Use ARIA only when native semantics are insufficient.
- Give inputs, controls, and icon buttons accessible names; associate labels, instructions, and errors programmatically.
- Support keyboard operation with logical focus order, visible `:focus-visible` treatment, no keyboard traps, and no author-created content that fully obscures the focused control.
- Meet text contrast of 4.5:1 for normal text and 3:1 for large text. Give required control boundaries, states, focus indicators, and meaningful graphics at least 3:1 contrast against adjacent colors.
- For WCAG 2.2 AA, make pointer targets at least 24 by 24 CSS px or satisfy an applicable WCAG exception. Prefer 44 by 44 for frequent or touch-first controls; require it when the product contract targets that size or WCAG AAA.
- Respect `prefers-reduced-motion`, provide control over non-essential autoplay or motion, and announce loading, error, success, and empty-state changes when assistive technology needs them.

## Ethical Guardrails

Reject these patterns and offer a transparent alternative.

- Hidden or obstructed cancellation, deletion, opt-out, unsubscribe, or account closure.
- Charges, renewals, or trials without clear prior consent, visible terms, and an accessible cancellation path.
- Guilt-based copy, fake urgency, fake scarcity, fake countdowns, or fake social proof.
- Pre-checked consent or extra-charge choices and misleading labels, colors, placement, or button hierarchy.
- Infinite scroll, autoplay, or reward loops without an obvious escape, pause, or control.

Use good friction only when it protects the user, such as destructive-action confirmation, payment review, undo windows, and review steps for irreversible changes.

## Completion Gate

Before reporting a UI task complete, verify and fix every miss in the same final path.

- The first useful state loads only its critical UI, data, and assets; every deferred delivery has a clear trigger, and critical resources are not incorrectly lazy-loaded.
- Every required datum is traced to its authoritative producer, each data-affecting default has one owner, and downstream consumers do not fork that value.
- For an implemented data-delivery change, measure applicable data-source work, including query count, transferred or rendered payload size, and request, render, or stream sequence; remove work that belongs after the first useful state. Confirm that every deferred delivery applies the required authorization and input validation at each protected boundary.
- Layout edges, spacing, typography, boxes, and responsive placement form a readable hierarchy rather than visual clutter.
- Visual, DOM, focus, task, and data dependency order agree from prerequisites through results.
- Existing visual sources were reused, comparable components are consistent, and button treatment matches action meaning without relying on color alone.
- Tailwind styling follows the native-utility, minimal-token, and proportional-layout rules above.
- CTA, Hook, progress, and optimistic feedback appear only when appropriate to the screen and action risk.
- Accessibility and ethical guardrails above are satisfied.
- The rendered UI was inspected at every affected viewport and for each changed state: default, hover, focus, disabled, loading, error, empty, success, modal, and responsive. Source inspection and automated tests do not substitute for visual verification.
