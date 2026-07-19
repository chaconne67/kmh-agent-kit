---
name: web-automation
description: Use for browser investigation or automation involving scraping, downloads, login, form filling, posting, admin actions, Playwright, Selenium, or CDP.
---

# Web Automation

Use this skill before manipulating or extracting from a web page. Base browser behavior on the observed page and session, not guessed selectors, guessed URLs, or remembered flows.

Terminology:

- **Final-path implementation**: the durable functions, wrapper, and session service that own the browser workflow.
- **Final-path command**: the official CLI or service entry that invokes that implementation.

## Operation Gate

Before any browser action, declare the current phase. Declare again before changing phases.

| Phase | Purpose | Allowed path |
|---|---|---|
| **Investigation** | Observe, debug, inspect page structure, and reproduce behavior | Direct browser tools and inline inspection may create diagnostic evidence, but not the requested data, download, submission, publication, or external state |
| **Execution** | Produce requested data/downloads or persist authentication, drafts, submissions, publications, or admin state | Run the final-path command; do not substitute ad hoc browser manipulation |
| **Integration** | Convert investigation evidence into durable automation | Merge into the responsible final-path implementation stage and verify it through the final-path command |

Manual reproduction proves only observed page behavior, not the automation. If no final-path command exists, complete Integration before Execution rather than using direct manipulation as a fallback.

Execution must remain within the authority granted by the user. Stop before externally visible or destructive actions when approval is absent or ambiguous.

For Exdigm UI or template changes, also use [$exdigm-design](/home/chaconne/.codex/skills/exdigm-design/SKILL.md). Its project URL, interaction acceptance, and screenshot verification rules are the source of truth; this skill still owns browser phase classification.

## Preflight

Before launching or attaching to a browser:

- Identify the required browser, profile, session, owner, and lifecycle: existing user browser, dedicated automation profile, transient Playwright/Selenium context, remote Linux/Xvfb Chrome, or CDP-attached Chrome.
- Determine whether the site is profile, device, 2FA, CAPTCHA, approval, or human-session bound.
- Classify the intended effect as diagnostic evidence, read-only requested output, draft-only, externally visible, or destructive.
- Identify the final-path command for Execution or declare that Integration is required first.
- Follow a user-provided browser/profile path exactly. Do not replace it with a fresh profile or another environment.
- If a required browser, profile, tool, credential, or approval is unavailable, stop and report the missing dependency instead of substituting another path.

## Investigation

Use this loop only for Investigation:

```text
Observe -> inspect structure -> map visible controls -> perform one scoped action -> verify state -> continue or stop
```

Exit Investigation when each safe-to-probe step has a verified selector/action and diagnostic postcondition, and each execution-only step has an explicit required postcondition. Do not repeat an unchanged action after the same blocker; preserve the session and evidence, then retry only when a verified premise or input has changed.

### Page Readiness

Do not treat `domcontentloaded` alone as readiness. Record the URL, title, ready state, visible text marker, viewport, and scroll height. Wait for the expected account/session marker, visible control, stable URL/title, loader completion, and required modal or frame.

### Structure Inspection

Before choosing selectors, inspect frames, shadow roots, modals, popups, virtualized lists, and rich text editor iframes.

Record each candidate frame's identity, URL, visibility, and ownership. Do not use main-DOM selectors until the target frame, modal, or popup owner is resolved.

### Control Mapping

Map visible controls before acting. Record the tag, accessible name, text, state, rectangle, form owner, and frame owner needed to distinguish each candidate. Capture evidence before safe navigation or a reversible page-state action. Map authentication or persistent-state controls, but defer their use to Execution.

Prefer human-visible controls over hidden/raw inputs:

1. Exact visible label tied to the input.
2. Visible button/control inside the correct section.
3. Coordinate click on the measured visible control.
4. Raw input click only after proving it triggers the same state.
5. Direct value assignment only after React/value tracker events are handled correctly.

### Step Contract

For every investigated step, record:

```text
precondition
selector/action
postcondition
failure evidence
```

During Investigation, perform one safe scoped action and verify URL/title/body markers, modal state, or reversible field state. Record persisted postconditions such as created/removed items, files, emails, or API responses without producing them directly; Execution verifies them through the final-path command.

Treat direct URLs and `href`s as hypotheses. For safe navigation, click the visible link once, observe behavior, compare direct navigation only after that, and preserve the click flow when JS/session state differs.

## Integration and Verification

After Investigation, stop before editing. Lock these four items:

1. Observed state and evidence.
2. Existing final-path implementation and command.
3. Exact merge point and successful behavior that must remain unchanged.
4. Verification command and expected postconditions.

Do not change a previously successful final-path stage or deployment path until its prior success contract is understood. If verification fails, return to Investigation and change the existing stage that owns the evidenced cause—such as the browser function, wrapper, or session service—instead of adding a temporary runner, bypass, or parallel workflow.

Build the durable script only after the flow is mapped. Encode:

- exact entry URL from env/config/user instruction
- browser/profile ownership and lifecycle requirements
- frame/modal resolution
- verified selectors and postconditions
- configured evidence artifacts and paths
- project-defined safety modes and approval gates
- project-approved credential inputs and redacted logs/evidence; never emit secrets, OTPs, cookies, tokens, or passwords

Verification passes only when the final-path command produces the required postconditions and evidence. Manual success, inline inspection, a temporary runner, or a separately corrected result does not pass. Follow the host project's recovery rule when verification fails; do not leave unverified integration in the final path.

Never close, kill, or delete a user-owned, shared, or persistent browser/profile, including one with an authenticated session. Close only a transient context created and owned by the current final-path run, after verification evidence is saved and no follow-up step needs the session.

## Stop Conditions

Stop and report evidence instead of continuing when:

- an externally visible or destructive action lacks clear user authority;
- the required browser, profile, tool, credential, approval, or final-path command is unavailable;
- the same blocker recurs without a changed, verified premise;
- an authentication challenge has no approved handling path;
- the requested postcondition cannot be verified.

For service-style wrappers and reusable CLI architecture, read [service-wrapper-pattern.md](/home/chaconne/.codex/skills/web-automation/references/service-wrapper-pattern.md).
