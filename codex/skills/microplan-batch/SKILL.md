---
name: microplan-batch
description: Use when the user says "microplan-batch", "구현 배치", "계획문서 디렉토리 순차 구현", or asks to sequentially execute microplan task documents from a directory.
---

# Microplan Batch

Sequential execution orchestrator for a directory of plan documents. This is not limited to `*-agreed.md`; every selected Markdown plan in the directory is a task unless the user excludes it.

The purpose is practical execution, not perfect planning: process one document according to its type, verify the result, then move to the next document. Not every task is an implementation task. Some documents are readiness checks, final verification gates, or approval/operations gates and must not be forced through an implementation commit flow.

## Required Setup

At skill start:

1. Identify the plan directory from the user request. If absent, ask for it.
2. Identify planner-intent context documents before execution begins, for example `CONTEXT.md`, ADRs, domain specs, or memory files. Use documents the user already named; ask only if absent or ambiguous. These documents are passed into every task; implementation tasks also pass them into `microplan-verify`.
3. List candidate task documents:
   - default: `*.md` directly in the specified directory, sorted by filename
   - ignore hidden directories and generated progress/log files
   - include subdirectories only if the user asked for recursive execution
4. Classify each document before execution:
   - `implementation`: code/docs/config/data migration changes are expected.
   - `procedure-check`: readiness or baseline checks; no implementation output is expected.
   - `verification-gate`: integration/final verification; normally no code changes.
   - `approval-gate`: human approval, production deployment, credentials, backup, cost, or external side effects are required.
5. Show the execution order and ask for approval if the task list is ambiguous or includes obvious non-implementation gates whose behavior is not specified by the document.
6. Always ask the user to choose the execution mode before starting or resuming a batch run. Do not infer the mode from previous recommendations, task size, wording, or an earlier mention:
   - `foreground`: run in the current Codex session.
   - `background`: create a session prompt and launch `codex exec` with `setsid`, then report the log paths and return.

## Progress File

Create `microplan-progress.json` in the plan directory while the batch is running. It is the resume source across context compaction or new sessions.

Minimal shape:

```json
{
  "skill": "microplan-batch",
  "plan_dir": "docs/plans/example",
  "context_docs": ["CONTEXT.md"],
  "batch_status": "running",
  "execution_mode": "foreground",
  "codex_exec_flags": "--dangerously-bypass-approvals-and-sandbox",
  "last_pid": null,
  "current": null,
  "quality_observations": [],
  "compound_candidates": [],
  "tasks": [
    {
      "slug": "00-readiness-check",
      "plan": "docs/plans/example/00-readiness-check.md",
      "kind": "procedure-check",
      "status": "pending",
      "workspace": null,
      "base_sha": null,
      "task_commit": null,
      "verification": null,
      "fresh_verification": null,
      "code_review_loop": null,
      "attempts": 0,
      "failure_signatures": [],
      "reason": null
    }
  ]
}
```

Task status values: `pending`, `running`, `completed`, `failed`, `skipped`, `blocked`.

Batch status values: `running`, `complete`, `complete_with_failures`, `failed`, `blocked`.

`quality_observations` stores repeated failure signals across tasks. `compound_candidates` stores solved or important lessons that should be documented with the Superpowers `compound` skill when available.

Delete `microplan-progress.json` after the whole batch completes successfully. If the batch fails, is interrupted, completes with failures/skips, or is blocked, keep it for resume.

## Quality Observation

At each task boundary, scan the current task result and prior `microplan-progress.json` entries for repeated mistakes before moving to the next task.

Record a quality observation when any of these signals appears:

- The same command fails in more than one task.
- The same error message, file, module, migration, prompt, or test area fails repeatedly.
- One implementation task needs three fix attempts.
- Verification keeps finding the same mismatch between the plan and implementation.
- A plan is too ambiguous to implement without re-deciding scope or completion.

When a quality observation appears:

1. Add a short entry to `quality_observations` with `task`, `signal`, `evidence`, and `action`.
2. If the task is still failing, stop local patching and apply systematic root-cause investigation before another fix attempt.
3. If the lesson has been solved or is important for future batches, add a `compound_candidates` entry with `lesson`, `prevention`, and `evidence`.
4. If the same observation blocks later dependent tasks, mark those tasks `skipped` instead of repeating the same failure.

Do not turn quality observation into a broad review. It exists to stop repeated waste while preserving the batch's one-task-at-a-time execution model.

## Execution Modes

### Foreground

Run the per-task workflow in the current Codex session. Use this for small batches or when the user wants to watch and steer each step.

### Background

Use background mode when the user wants the batch to continue outside the current conversation. Background mode uses `codex exec`, `microplan-progress.json`, a prompt file in the plan directory, and a cron/systemd periodic monitor.

Create these files while the batch runs:

- `microplan-progress.json`: resume/progress state.
- `session-prompt.txt`: the prompt used by background Codex sessions.
- `logs/session.log`: JSONL/event log from `codex exec`.
- `logs/last-message.txt`: final message from the last background session.
- `logs/exit.code`: exit code from the last background session.
- `logs/monitor.log`: cron/systemd monitor checks and respawn events.

Delete these orchestration files only after successful completion with zero failures/skips:

- `microplan-progress.json`
- `session-prompt.txt`
- `logs/session.log`
- `logs/last-message.txt`
- `logs/exit.code`
- `logs/monitor.log`

Keep `microplan-progress.json`, `session-prompt.txt`, and `logs/` if the batch fails, is interrupted, completes with failures/skips, or is blocked.

Remove or disable the cron/systemd monitor whenever the batch reaches any terminal status: `complete`, `complete_with_failures`, `failed`, or `blocked`. Terminal batches must not leave a periodic monitor behind even when orchestration files are preserved for diagnosis or resume.

`session-prompt.txt` should tell the background session:

```text
You are continuing a microplan-batch run.

Plan directory: {plan_dir}
Progress file: {plan_dir}/microplan-progress.json
Context documents: {context_docs}

Use the microplan-batch skill. Read microplan-progress.json, continue from the first pending or interrupted task, perform exactly one task if the file says the batch is still running, update microplan-progress.json, and if more tasks remain launch the next background session using the same setsid codex exec pattern. If the batch reaches a terminal status, run the bundled `check_and_respawn.py` once after recording the terminal status and before removing the cron/systemd monitor so the terminal Telegram notification is sent. If the batch is complete with zero failures/skips, then delete the orchestration files, remove the cron/systemd monitor, and stop. If the batch is failed, complete_with_failures, or blocked, preserve orchestration files, remove the cron/systemd monitor, and stop.

Before acting, classify the task document as implementation, procedure-check, verification-gate, or approval-gate. Only implementation tasks change code and create commits. Procedure and verification gates run their documented checks and record the result. Approval gates stop with status blocked when user approval or production/external action is required.

For every implementation task, after implementation and microplan verification have produced a candidate diff but before committing, invoke `$code-review-loop` in a separate subagent against the active task workspace. The subagent must review, fix, validate, and re-review only that task diff until no actionable findings remain or it reports a blocker. After the subagent finishes, rerun focused checks and `microplan-verify` in the main batch session before committing the task. Do not continue to the next task until this gate passes.

At each task boundary, update quality_observations and compound_candidates in microplan-progress.json when the same command, error, file area, verification mismatch, or plan ambiguity repeats. If one task reaches three fix attempts, stop guessing and perform root-cause investigation before another fix. Do not continue into dependent tasks that would repeat the same known failure.
```

Launch with the verified detached pattern:

```bash
PLAN_DIR="{plan_dir}"
mkdir -p "$PLAN_DIR/logs"
CODEX_EXEC_FLAGS="${CODEX_EXEC_FLAGS:-$(python3 - "$PLAN_DIR/microplan-progress.json" <<'"'"'PY'"'"'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    print(data.get("codex_exec_flags") or "--dangerously-bypass-approvals-and-sandbox")
except Exception:
    print("--dangerously-bypass-approvals-and-sandbox")
PY
)}"
setsid bash -c '
codex exec \
  --cd /path/to/repo \
  $1 \
  --json \
  --output-last-message "$0/logs/last-message.txt" \
  - < "$0/session-prompt.txt" \
  > "$0/logs/session.log" 2>&1
echo $? > "$0/logs/exit.code"
' "$PLAN_DIR" "$CODEX_EXEC_FLAGS" </dev/null >/dev/null 2>&1 &
echo $!
```

Record the returned PID in `microplan-progress.json.last_pid`.

Background mode defaults to `--dangerously-bypass-approvals-and-sandbox` because the user already asked for unattended execution, and some Linux/container environments make `codex exec --full-auto` fail before any local command can run. If the user explicitly overrides `CODEX_EXEC_FLAGS=--full-auto`, immediately after the first launch run a short sanity check for sandbox setup failure. This is needed because `codex exec --full-auto` can exit successfully at the CLI level while the agent failed every local command before updating `microplan-progress.json`:

```bash
PLAN_DIR="{plan_dir}"
pid="$(python3 - "$PLAN_DIR/microplan-progress.json" <<'"'"'PY'"'"'
import json, sys
print(json.load(open(sys.argv[1])).get("last_pid") or "")
PY
)"

for _ in 1 2 3 4 5 6; do
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    sleep 5
  else
    break
  fi
done

if grep -Eiq "bwrap: loopback|Failed RTM_NEWADDR|Operation not permitted" \
  "$PLAN_DIR/logs/session.log" "$PLAN_DIR/logs/last-message.txt" 2>/dev/null; then
  echo "$(date -Is) sandbox fallback: --full-auto failed; relaunching without codex sandbox" >> "$PLAN_DIR/logs/monitor.log"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi
  CODEX_EXEC_FLAGS="--dangerously-bypass-approvals-and-sandbox"
  python3 - "$PLAN_DIR/microplan-progress.json" "$CODEX_EXEC_FLAGS" <<'"'"'PY'"'"'
import json, os, sys, tempfile
path, flags = sys.argv[1], sys.argv[2]
data = json.load(open(path))
data["codex_exec_flags"] = flags
data["reason"] = "codex exec --full-auto failed before local commands with bwrap/loopback sandbox setup error; background run relaunched with --dangerously-bypass-approvals-and-sandbox."
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), text=True)
with os.fdopen(fd, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, path)
PY
  : > "$PLAN_DIR/logs/session.log"
  : > "$PLAN_DIR/logs/last-message.txt"
  setsid bash -c '
codex exec --cd /path/to/repo $1 --json \
  --output-last-message "$0/logs/last-message.txt" \
  - < "$0/session-prompt.txt" \
  > "$0/logs/session.log" 2>&1
echo $? > "$0/logs/exit.code"
' "$PLAN_DIR" "$CODEX_EXEC_FLAGS" </dev/null >/dev/null 2>&1 &
  new_pid=$!
  python3 - "$PLAN_DIR/microplan-progress.json" "$new_pid" <<'"'"'PY'"'"'
import json, os, sys, tempfile
path, pid = sys.argv[1], int(sys.argv[2])
data = json.load(open(path))
data["last_pid"] = pid
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), text=True)
with os.fdopen(fd, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, path)
PY
fi
```

Notes:

- Do not use `--ask-for-approval` with `codex exec`; it is not a valid exec option.
- Use `--dangerously-bypass-approvals-and-sandbox` by default for background execution. This avoids the known `--full-auto`/bwrap loopback failure in trusted unattended repo runs.
- Use `--full-auto` only when the user explicitly requests sandboxed background execution or the environment is known to support Codex's bwrap sandbox.
- If a user-overridden `--full-auto` background session cannot execute local commands because sandbox setup fails before command execution (for example a `bwrap`/loopback permission error), relaunch with `CODEX_EXEC_FLAGS="--dangerously-bypass-approvals-and-sandbox"` when the environment is already trusted for this repo and the user explicitly requested unattended background execution. Record the fallback in `logs/monitor.log` and `microplan-progress.json.codex_exec_flags`.
- Once fallback is selected, every later session and periodic monitor respawn must read and reuse `microplan-progress.json.codex_exec_flags`; do not go back to `--full-auto` inside the same batch.
- Use `--json` so logs are machine-readable enough to inspect later.
- Background mode still runs tasks sequentially. Each session should finish one task according to its classified kind, update progress, and spawn the next session if tasks remain. Only implementation tasks change code and create commits.

### Periodic Monitor

In background mode, register a periodic monitor after the first background session. Prefer cron or a systemd timer. The monitor runs once, checks the plan directory, respawns the background session only if needed, and exits. Do not keep a long-running watchdog loop for this job.

Purpose:

- detect a dead `last_pid` while `batch_status` is still `running`
- detect `codex exec --full-auto` sandbox setup failure in `logs/session.log` or `logs/last-message.txt`
- relaunch the same `session-prompt.txt` only when needed
- send a Telegram progress report only when a task completes, fails, is skipped, is blocked, the batch reaches a terminal status, or the monitor respawns a dead session
- do nothing when the batch is no longer `running`

Cron pattern:

Use the bundled Python checker. It performs exactly one check and exits.

```bash
PLAN_DIR="{plan_dir}"
(crontab -l 2>/dev/null | grep -v "microplan-batch:{batch_id}"; \
  echo "*/5 * * * * cd /path/to/repo && flock -n /tmp/microplan-batch-{batch_id}.lock python3 /home/chaconne/.codex/skills/microplan-batch/scripts/check_and_respawn.py --plan-dir /path/to/repo/$PLAN_DIR --repo-dir /path/to/repo --cron-tag microplan-batch:{batch_id} >> /path/to/repo/$PLAN_DIR/logs/cron.log 2>&1 # microplan-batch:{batch_id}") | crontab -
```

Rules:

- Default cadence is 5 minutes.
- Use `flock` so cron cannot start overlapping checks.
- Do not inline the monitor loop with nested heredocs inside `bash -c`; use the bundled Python checker above.
- A dead PID does not prove task failure; it only means the orchestration session ended. The resumed session must read `microplan-progress.json` and git state before deciding what to do.
- Progress reporting belongs inside the bundled checker. The skill only installs the cron/systemd monitor.
- Do not send heartbeat messages. If the checker runs and there is no task completion, failure, skip, block, terminal status, or respawn, do not send Telegram.
- When sending progress, pass `microplan-progress.json`, recent logs, and recent git commits to an agent summarizer. Send the agent's concise Korean summary, not raw logs.
- Record the last reported progress signature in `microplan-progress.json.notifications` so the same state is not reported repeatedly.
- Remove the cron/systemd monitor entry after any terminal status: `complete`, `complete_with_failures`, `failed`, or `blocked`. Before removing it from a background session that directly wrote the terminal status, invoke `check_and_respawn.py --plan-dir ... --repo-dir ... --cron-tag ...` once so the terminal Telegram notification is emitted immediately instead of waiting for a cron tick that may never run. For `failed`, `complete_with_failures`, or `blocked`, leave the orchestration files but remove or disable the monitor entry.
- Pass `--cron-tag microplan-batch:{batch_id}` to the checker so the next cron tick can remove its own entry if a terminal status is reached and the background session missed cleanup.

### Telegram Notification

Follow the Claude `forge-plans-batch` notification model: use a Bot API helper with the `SUPERUSER` namespace. Notification is best-effort; missing config or API failure never fails the batch.

Required config for the `SUPERUSER` namespace:

```text
TELEGRAM_BOT_TOKEN_SUPERUSER=...
TELEGRAM_CHAT_ID_SUPERUSER=...
```

Config lookup order:

- shell environment
- `~/.codex/mcp/telegram/state/.env`
- `~/.claude/channels/telegram/.env`
- `$PWD/.env`
- project-root `.env`

Helper:

```bash
source "$HOME/.codex/mcp/telegram/lib/telegram.sh"
notify_telegram "$PLAN_DIR" "<subject>" "<body>" "SUPERUSER"
```

Notification triggers:

| Timing | Subject | Meaning |
|---|---|---|
| individual task failed after retry | `microplan-batch FAILED` | informational; batch may continue to next independent task |
| task completed or skipped | `microplan-batch PROGRESS` | progress changed |
| orchestration stuck or background respawn failed | `microplan-batch STUCK` | user intervention needed |
| dead background session respawned | `microplan-batch RESPAWN` | monitor restarted execution |
| approval gate reached | `microplan-batch BLOCKED` | waiting for user approval or external action |
| batch complete with zero failures | `microplan-batch COMPLETE` | final completion |
| batch complete with failures/skips | `microplan-batch COMPLETE_WITH_FAILURES` | final completion with follow-up needed |

Final message body shape:

```text
directory: {plan_dir}
성공: {completed}/{total}
실패: {failed}
스킵: {skipped}
대기: {blocked}
마지막 커밋: {last_task_commit}
상태: complete|complete_with_failures|failed|blocked
```

Rules:

- Telegram send is best-effort only.
- Never store bot tokens or credentials in skill files or progress files.
- `notify_telegram` must return success even when notification is skipped or fails.
- Progress messages must be generated from a concise agent summary of progress data, recent logs, and recent git commits.
- Do not send progress messages on unchanged monitor ticks.
- Send notification once when `batch_status` changes to `complete`, `complete_with_failures`, `failed`, or `blocked`, and immediately on stuck states that require manual intervention.
- In background mode, send the terminal notification before removing the cron/systemd monitor and before stopping the session. If the session misses it, the periodic checker must send it on the next terminal-status check before removing its own cron entry.
- Record a lightweight marker in `microplan-progress.json.notifications`, for example `telegram:blocked`, after a terminal notification attempt so retries do not spam the user.

## Per-Task Workflow

For each task in order:

1. Read the plan document and context documents.
2. Classify the task from its title, purpose, sections, and explicit wording:
   - Classification priority: `approval-gate` first, then `verification-gate`, then `procedure-check`, then `implementation`.
   - If a document contains production/deploy/backup/credential/external-action wording, classify it as `approval-gate` even if it also contains commands.
   - If a document says code changes are not expected or failures should be fixed in earlier tasks, classify it as `verification-gate` even if it runs tests.
   - `procedure-check`: "readiness", "baseline", "checklist", "절차", "완료 확인", or a document that only asks to inspect/run checks.
   - `verification-gate`: "final verification", "통합 검증", "smoke", or a document that says code changes are not expected.
   - `approval-gate`: "production", "deploy gate", "승인", "backup", "사용자가 직접", credentials, external services, or irreversible/costly actions.
   - `implementation`: any document that names changed files, tests to write, migrations, deletes, refactors, or concrete edits.
3. Record `kind` and `status: running` in `microplan-progress.json`.
4. Before executing the task, check `quality_observations` for a repeated failure that affects this task. If the task depends on an unresolved repeated failure, mark it `skipped` with the reason instead of reproducing the same failure.
5. After the task completes, fails, or blocks, update `fresh_verification`, `failure_signatures`, `quality_observations`, and `compound_candidates` before moving to the next task.

### Procedure Check

For `procedure-check` tasks:

1. Run only the checks named by the document, normally in the active repository workspace.
2. Do not create a task worktree.
3. Do not commit.
4. If the check passes, record `status: completed`, `verification`, `fresh_verification`, and `task_commit: null`.
5. If the check fails, record `status: failed`, preserve the reason, set `batch_status: failed`, and stop unless the document explicitly says the batch may continue.

### Verification Gate

For `verification-gate` tasks:

1. Run the documented integration/final checks against the active repository workspace.
2. Do not create a worktree or commit for the gate itself.
3. If a check fails, record the failing command/output summary and mark the gate `failed`. Do not make new fixes inside the gate unless the document explicitly instructs that failures should be fixed there.
4. If all checks pass, record `status: completed`, `verification`, `fresh_verification`, and `task_commit: null`.

### Approval Gate

For `approval-gate` tasks:

1. In background mode, do not perform production deploys, production DB backups, credentialed external actions, paid actions, or user-owned external work.
2. Run only safe local/reporting checks that the document asks for before approval.
3. Record `status: blocked`, `reason` describing the required approval/action, and set `batch_status: blocked`.
4. Stop and report the gate. The user can resume after approval or after performing the required external action.
5. On resume, ask the user to choose `foreground` or `background` again before continuing the blocked gate. Do not infer approval or execution mode from elapsed time, previous mode, or the existence of a blocked progress file.
6. If the user already performed the external action, run only the verification checks named by the document, then mark the gate `completed`.
7. If the user explicitly approves Codex to perform an external action, perform only the exact action named and approved in the current conversation and only if the plan document allows Codex to perform it. If the document says the user must perform an action personally, keep the task `blocked` until the user confirms it is done.

### Implementation Task

#### Workspace Policy

Respect the repository's branch and worktree rules before choosing where to run implementation tasks.

If the repository policy restricts work to named branches, use that policy. For Exdigm, run implementation tasks serially in the normal `/home/chaconne/exdigm` worktree on `dev`; create one commit per implementation task; promote to `main` only through the deploy workflow after development validation.

Use a separate git worktree only when the repository policy permits it or the user explicitly approves it for the current batch. Reasons include concurrent work in the main workspace, dirty user changes that must not be touched, or an unattended long-running batch where isolation is worth the extra branch/worktree cleanup.

When a separate worktree is approved, create a batch integration branch/worktree and task worktrees from its current `HEAD`; do not merge task worktrees directly into `main`:

```bash
git worktree add .worktrees/batch-{batch_id} -b batch/{batch_id} HEAD
git -C .worktrees/batch-{batch_id} worktree add ../{slug} -b impl/{slug} HEAD
```

After an approved separate-worktree batch is finally integrated into the repository-approved target branch, delete temporary task branches, temporary task worktrees, the batch integration worktree, and the `batch/{batch_id}` branch. Keep them only when the batch is failed, blocked, or complete_with_failures and they are needed for diagnosis or resume.

Commit boundaries are implementation task boundaries. Each implementation task must produce its own commit after its implementation, verification, and code-review-loop gate pass. Do not combine multiple implementation tasks into one commit. Do not carry uncommitted changes from one implementation task into the next.

#### Code Review Loop Gate

Every implementation task has a mandatory code-review-loop gate before commit.

Run this gate after `microplan-implement`, focused checks, and `microplan-verify` have produced a candidate task diff, and before committing the task.

Rules:

- Invoke `$code-review-loop` with an available multi-agent/subagent capability, not as an informal review inside the main batch agent.
- Do not create a user-owned Codex thread for this gate.
- Give the subagent only the active task workspace path, task plan, context documents, current diff, and required checks.
- Tell the subagent to review, fix, validate, and re-review only the current task diff until no actionable findings remain.
- The subagent may edit only the active task workspace.
- If no subagent capability is available, mark the task `blocked`; do not skip the gate.
- If the subagent reports a blocker, record it in `code_review_loop`, `failure_signatures`, and `reason`, then mark the task `failed` or `blocked` according to the blocker.
- If the subagent changes code, rerun the task's focused checks and `microplan-verify` in the main batch session.
- Record the subagent result in `microplan-progress.json.tasks[].code_review_loop` with `status`, `summary`, `checks`, and `findings_remaining`.

Subagent prompt contract:

```text
Use $code-review-loop on this implementation task workspace only.
Workspace: {worktree_or_repo_path}
Task plan: {plan}
Context documents: {context_docs}
Required checks: {checks}

Review the current task diff, fix actionable findings in this workspace only, run focused checks, and re-review until clean or blocked. Return status, remaining findings, changed files, and checks run. Do not merge, commit, or edit outside this workspace.
```

For `implementation` tasks:

1. Confirm the current branch/workspace matches the repository policy. For Exdigm, stop unless the current branch is `dev`.
2. Record the active workspace path, `base_sha`, branch, and `status: running` in `microplan-progress.json`.
3. Use `microplan-implement` in the active workspace for the single task.
4. Run the plan's focused tests/checks inside the active workspace. If the plan names no checks, infer the narrowest useful checks from changed files.
5. Run `microplan-verify` using:
   - the task plan
   - all context documents
   - the current task diff
6. Before each fix attempt after a failed implementation or verification run, increment the task's `attempts` count. If `attempts` reaches 3, stop making fixes, record the repeated failure in `quality_observations`, and perform root-cause investigation before any further code change.
7. Fix concrete `FAIL` items in the active workspace and rerun focused checks.
8. Invoke the mandatory code-review-loop gate in a separate subagent. If it fixes code, rerun focused checks and `microplan-verify`.
9. Record `fresh_verification` and `code_review_loop` with final command/status summaries. Do not mark the task completed from stale or assumed verification.
10. Stage only the current task's files and commit the active workspace when implementation, verification, and code-review-loop all pass.
11. Confirm the workspace is clean before starting the next task.
12. Record `status: completed` and `task_commit`.

## Failure Handling

- If implementation or verification fails after reasonable retry, mark the task `failed`, keep `microplan-progress.json`, and preserve useful notes in the progress `reason`. Continue only when later tasks are clearly independent; otherwise set `batch_status: failed` and stop.
- If the code-review-loop gate fails or is unavailable, do not commit the task. Record the gate result and stop or continue only when later tasks are clearly independent.
- If a failure pattern repeats, record the repeated signal in `quality_observations` before deciding whether to continue. Later tasks that depend on the same unresolved signal are `skipped`, not retried blindly.
- If a repeated failure is solved or an important batch lesson emerges, add a `compound_candidates` entry. At the end of the batch, report these candidates and use the Superpowers `compound` skill when it is available and the current request permits writing the learning note.
- If a procedure or verification gate fails, mark it `failed`, set `batch_status: failed`, and stop. The failure means a required condition was not met, not that code should be invented in that gate.
- If an approval gate is reached, mark it `blocked`, set `batch_status: blocked`, and stop for user action.
- If all remaining executable tasks are done but any earlier task is `failed` or `skipped`, set `batch_status: complete_with_failures`, preserve orchestration files, and report the follow-up needed.
- If a later task clearly depends on a failed task, mark it `skipped`.
- If the active workspace changed unexpectedly while a task was running, stop and report. Do not commit over external changes.
- Never revert user changes or unrelated dirty worktree changes.

## Verification Policy

- Implementation tasks must pass their own focused checks before commit.
- Completion requires fresh verification evidence from the current task run. Do not mark a task `completed` because an earlier run passed or because the implementation looks correct.
- Store the final proof in `fresh_verification`: command, exit status, and one-line result.
- Use `microplan-verify` after implementation tasks, not before. Do not require `microplan-verify` for tasks with no diff.
- Procedure and verification gates must pass the checks explicitly named in the document.
- Treat plan/context documents as intent, but allow implementation-time correction when tests or current code reveal stale details.
- Migration tasks must include `migrate`, `makemigrations --check --dry-run`, or the narrowest equivalent when feasible.
- Report any checks not run and why.

## No Extra Artifacts

Do not create separate reports, agreed-doc copies, failed-task directories, or generated documentation unless the user asks. The only orchestration artifacts are `microplan-progress.json` and, in background mode, `session-prompt.txt` plus `logs/`. Delete orchestration artifacts only on zero-failure `complete`; keep them for `failed`, `complete_with_failures`, `blocked`, or interrupted runs.

## Resume

If `microplan-progress.json` already exists in the plan directory:

1. Read it first.
2. Compare recorded workspace, commits, and any recorded worktrees with `git status`, `git worktree list`, and `git log`.
3. If `batch_status` is `blocked`, report the blocked task and reason first. Continue only after the user explicitly approves the next action or confirms the required external action is done.
4. For an approved blocked `approval-gate`, set that task back to `running`, complete the approved/verification steps, then set it to `completed` or keep it `blocked` with an updated reason.
5. If `batch_status` is `failed`, `complete_with_failures`, or interrupted, continue from the first `pending` or interrupted `running` task only when doing so is safe and the user requested resume.
6. If the progress file is inconsistent with git state, report the inconsistency and choose the safest state-preserving recovery.
