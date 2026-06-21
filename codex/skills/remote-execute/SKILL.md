---
name: remote-execute
description: Run heavy repository jobs on the remote worker chaconne@49.247.45.243 and bring back Git commits or selected large artifacts. Use when Codex needs to execute data extraction, microplan-batch, Playwright/screenshot checks, long tests, expensive batch jobs, or other memory/CPU-heavy repo tasks away from the local/production server.
---

# Remote Execute

Use this skill to move heavy repo work to `chaconne@49.247.45.243`. The remote worker is expected to have a GitHub SSH key registered. Transfer source state through Git commits and branches; transfer large generated artifacts with `rsync`/`scp`, not Git.

## Core Rule

Never execute remote work from uncommitted local state. First make the intended local state reproducible:

1. Inspect `git status --short`.
2. Commit or explicitly exclude local changes.
3. Push a dedicated branch.
4. Run the task on the remote worker from that branch.
5. Have the remote worker commit and push results.
6. Fetch and inspect Git results locally before merge/cherry-pick.
7. Download large artifacts separately only when they are needed locally.

If local changes are unrelated or unsafe to commit, stop and ask what should be included.

If the task requires a new command, option, helper script, schema, prompt, or test fixture before remote execution, implement and verify that change locally first, then commit and push it before running anything on the remote worker. Remote execution must run code that can be reproduced from Git, not code that only exists in the local working tree.

## Standard Flow

Use the bundled helper for ordinary repo tasks:

```bash
python3 ~/.codex/skills/remote-execute/scripts/remote_execute.py \
  --command 'uv run --extra dev pytest tests/test_project_detail_layout.py -v'
```

The helper:

- requires a clean local worktree
- pushes `HEAD` to a `remote-exec/...` branch
- clones or updates the repo on the remote worker
- runs the command there
- pushes remote commits back to the same branch
- prints local fetch/merge guidance

Use Git only for source code, plans, schemas, scripts, tests, and small reports. Do not commit extracted text corpora, batch JSONL outputs, PDFs, screenshots/videos, model outputs, DB dumps, or other large artifacts unless the user explicitly asks and the repo is designed for that storage.

For long-running agent jobs, pass the exact command that should run on the remote worker. Prefer foreground remote execution when the current session can wait. Use background remote execution only when the job has its own progress files/logs and a clear resume path.

## Microplan Batch

For `microplan-batch` or large verification batches:

1. Commit the plan/progress setup locally if it should travel to the remote worker.
2. Push a dedicated branch such as `remote-exec/microplan-YYYYMMDD-HHMM`.
3. Run the batch on the remote worker.
4. Require each completed task to commit on the remote branch.
5. Fetch the branch locally and review `git log HEAD..origin/<branch>` and `git diff HEAD..origin/<branch>`.

Do not let remote work touch production credentials, production DBs, paid external APIs, Drive/Gemini jobs, or Telegram notifications unless the user explicitly approves that external action for the remote server.

## Data Extraction

For exdigm data extraction jobs, this skill is the authoritative source for remote execution policy. Domain skills such as `data-extraction` may point here, but this section owns the rule.

Before any data extraction remote run:

1. `git status --short` must be clean, or the intended changes must be committed and pushed.
2. The remote repo must be updated to the pushed commit or branch before executing the job.
3. Artifact inputs may be generated locally after the code is pushed, but executable code must come from Git.
4. If the remote command fails because an artifact mode is missing, add the artifact mode locally, test it, commit, push, then retry remotely.

Remote execution is an artifact generator, not a DB worker:

- The remote worker must not read from or write to the operational DB.
- The remote worker receives file artifacts such as manifests, text files, JSON, or JSONL.
- The remote worker produces file artifacts such as extracted text, completed JSON, JSONL, reports, checksums, or logs.
- Bring the generated artifacts back with `rsync`/`scp`.
- All DB export, import, update, candidate matching, current-profile sync, and relation-table writes happen on the local/operational server.
- If a data extraction command can only run by connecting the remote worker to the operational DB, do not run it remotely. First add or use an artifact mode: local export file -> remote transform -> local import file.
- Even small remote tests follow the same boundary. For example, a 10-row test exports 10 DB rows to JSONL locally, transforms that JSONL remotely, downloads the result JSONL, then imports or verifies it locally.

Terminology rule:

- `remote worker` means `chaconne@49.247.45.243`.
- `Gemini Batch` means an external Gemini API batch job submitted from the local/operational server.
- Do not call Gemini Batch "remote execution" or "remote processing". Its request, polling, result download, ingest, and DB save are local/operational responsibilities unless the user gives fresh approval for remote credentials and external API side effects.
- `reconcile` has two separate meanings: `batch_txt_to_db --reconcile` reconciles Gemini Batch jobs locally; `remote_structured_json_classification.sh reconcile` reconciles remote worker artifacts locally. Always name the command when saying "reconcile".

Use remote execution only for local, reproducible stages unless credentials and external side effects are explicitly approved. Keep bulk outputs on the remote worker and download selected artifacts directly.

Recommended remote artifact root:

```text
~/remote-exec/artifacts/<repo>/<job-id>/
```

Record artifact paths and a compact manifest in the remote result commit or final report. Download only the needed outputs:

```bash
rsync -av --progress \
  chaconne@49.247.45.243:~/remote-exec/artifacts/exdigm/<job-id>/manifest.json \
  ./artifacts/<job-id>/
```

For directories, prefer resumable `rsync` with include/exclude filters over Git:

```bash
rsync -av --partial --progress \
  --include='*/' --include='*.json' --include='*.jsonl' --exclude='*' \
  chaconne@49.247.45.243:~/remote-exec/artifacts/exdigm/<job-id>/ \
  ./artifacts/<job-id>/
```

Safe examples:

- parser/test runs against committed fixtures
- batch prompt or schema tests
- dry-run extraction checks
- CPU-heavy local transforms
- remote generation of large intermediate files that stay outside Git
- text extraction from a manifest into text artifacts, followed by local DB import
- structured JSON search-classification enrichment from input JSONL to output JSONL, followed by local DB import

Unsafe without fresh approval:

- production Drive downloads
- Gemini Batch submission
- production DB writes
- operational DB reads for selecting work or verifying results
- credential copying

### Exdigm Artifact Patterns

For remote text extraction, the local server selects or exports the manifest, the remote worker downloads/parses files into text artifacts, and the local server imports those text artifacts into `FileStatus.extracted_text` and routing state.

For structured JSON search-classification enrichment, the local server exports rows that already have `FileStatus.structured_json` to JSONL, the remote worker runs the pure JSON transformation, and the local server imports the completed JSON back into DB.

Use the repository wrapper for long-running structured JSON search-classification enrichment jobs:

```bash
# Submit once: export local artifacts, upload them, and start the remote job in the background.
LIMIT=0 RUN_ID=json-classification-<name> scripts/remote_structured_json_classification.sh submit

# Reconcile repeatedly: poll remote state, download completed artifacts, verify checksums,
# import into local DB, and clean up the remote run dir.
scripts/remote_structured_json_classification.sh reconcile
```

`submit` must be run manually after the local code is clean, committed, and pushed. `reconcile` is the cron-safe operation and uses a lock so overlapping cron runs exit without doing duplicate work.

Keep local and remote executable paths separate. The local `UV_BIN` may be `/home/chaconne/.local/bin/uv`, while the remote worker currently resolves `uv` as `/usr/local/bin/uv`. Remote commands must use `REMOTE_UV_BIN` or `command -v uv` on the remote host; do not pass a local absolute `uv` path into the remote shell. Preflight should fail before backgrounding if the remote executable is missing.

For large imports, keep local DB pressure bounded. `remote_structured_json_classification.sh reconcile` imports completed JSONL in chunks (`IMPORT_CHUNK_SIZE`, default 500) and sleeps between chunks (`IMPORT_SLEEP_SECONDS`, default 2). Do not replace this with a one-shot import for large files unless memory, DB lock time, and rollback size have been considered.

After successful import, reconcile must clean the remote run directory. If a remote PID is still alive, terminate it only after confirming that the process command line belongs to the current run directory; never kill by stale PID alone.

Recommended structured JSON search-classification enrichment input JSONL:

```json
{"file_id":"<drive-file-id>","structured_json":{...}}
```

If completion logic needs DB-backed lookup data, export that lookup data as an artifact too. Current exdigm industry classification may use `CompanyProfile`, so pass a separate company profile JSONL instead of letting the remote worker query the operational DB:

```json
{"name":"삼성전자","name_en":"Samsung Electronics","industry":"반도체"}
```

Recommended structured JSON search-classification enrichment output JSONL:

```json
{"file_id":"<drive-file-id>","completed_structured_json":{...},"status":"ok"}
```

If a row fails, keep it as an artifact and do not hide it:

```json
{"file_id":"<drive-file-id>","status":"error","error":"<short reason>"}
```

The structured JSON search-classification enrichment remote command should call the same code path as local DB saving: `candidates.services.tagging.add_career_tags_to_extracted_json(extracted)`. Its input is an LLM structured JSON object, and its output is the completed JSON that includes `classification`, top-level `career_tags`, top-level `job_categories`, and per-career `classification`.

For checksums, create relative-path checksum files from inside the remote artifact directory:

```bash
cd "$REMOTE_DIR" && sha256sum completed.jsonl complete-report.json > checksums.sha256
```

After rsync, verify from inside the local artifact directory:

```bash
cd "$LOCAL_DIR" && sha256sum -c checksums.sha256
```

Do not create checksum manifests with remote absolute paths if they will be verified locally.

Run local Django management commands from the repository root with `uv run python manage.py ...`. Running `uv run` from an artifact directory can miss the repo virtualenv/project configuration.

If the output is large, prefer this result split:

- Git branch: code changes, prompt/schema changes, small manifests, checksums, summary reports.
- Artifact download: large extracted texts, JSONL payloads, screenshots, PDFs, DB dumps, model output batches.

## Result Intake

After remote execution:

1. `git fetch origin <remote-branch>`
2. Inspect commits and diff.
3. Run the narrowest local verification needed for confidence.
4. Merge, cherry-pick, or ask the user if the result includes unexpected changes.

Keep remote orchestration artifacts out of the main branch unless they are intentionally part of the task.

## Large Artifact Transfer

Use `rsync` for large outputs. It is resumable, can filter paths, and avoids bloating Git history.

Before downloading, inspect remote size:

```bash
ssh chaconne@49.247.45.243 'du -sh ~/remote-exec/artifacts/exdigm/<job-id> && find ~/remote-exec/artifacts/exdigm/<job-id> -maxdepth 2 -type f | head -50'
```

Download choices:

- one file: `scp remote:path local/path`
- resumable directory: `rsync -av --partial --progress remote:path/ local/path/`
- huge output: first download `manifest.json`, checksums, or sampled files; ask before pulling all data.

Never put downloaded bulk artifacts under tracked repo paths unless the project already expects them there. Prefer ignored local paths such as `artifacts/<job-id>/` or a user-specified data directory.

## Troubleshooting

- If SSH fails, run `ssh -T chaconne@49.247.45.243 'hostname && git --version'`.
- If GitHub fetch/push fails on remote, verify the remote worker's GitHub key and repo access.
- If the remote command leaves uncommitted changes, inspect on the remote path and commit there before pushing.
- If local worktree is dirty, commit only the intended state or use a temporary local branch.
