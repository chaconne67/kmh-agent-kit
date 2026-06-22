---
name: exdigm-deploy
description: Use when the user asks to deploy Exdigm, including "개발배포", "개발 서버에 배포", "운영배포", "운영 서버에 배포", "배포해줘", "dev deploy", "prod deploy", or asks how to promote a tested dev commit to main and production.
---

# Exdigm Deploy

## Core Rule

Treat the production server's current structure as the source of truth. The development server is a production-like validation server, not a separate convenience environment. Do not add or preserve extra containers, ports, DBs, services, or settings on development if production does not have the same class of component, unless the user explicitly approves a development-only exception.

Use Korean honorific language. Call the user "주인님" naturally when appropriate.

## Deployment Parity Rule

Do not fix production-only runtime problems by manually editing files on the production host. Fix them in the development branch, validate through the development deployment path, then promote and deploy the same source/image/scripts to production.

Development and production may differ only through values read from each server's `.env` or host-owned runtime data such as DB/media contents. Required host data normalization, such as public media file permissions needed by nginx, must be encoded in the shared deployment procedure so the same deploy command can repair development and production safely.

When investigating a production-only issue:

1. Compare development and production container/service/env/mounts first.
2. If the root cause is host runtime state, add an idempotent deploy-time normalization step instead of running a one-off production command.
3. Keep server-specific values in `.env`; do not fork Dockerfiles, stack templates, code paths, or manual production instructions for ordinary deployment differences.
4. Production is allowed to receive only the already-validated development commit via the promote/prod flow.

## Server Facts

- Project root: `/home/chaconne/exdigm`
- Development branch: `dev`
- Production branch: `main`
- Production server: `chaconne@115.68.224.161:/home/chaconne/exdigm`
- Development and production both run Exdigm with Docker Swarm stack `Exdigm`.
- Host-side Exdigm DB access should be `127.0.0.1:5432`.
- Container-side app DB access should be `exdigm_db:5432`.
- Do not use a separate local PostgreSQL for Exdigm validation.

## System Components

Treat Exdigm deployment as a set of coordinated host systems, not just the
Django web image:

- Web stack: Django app image, optional SSE service, nginx image, static/media,
  migrations, and workers.
- Database: the shared pgvector Postgres container. `exdigm` is the app DB;
  `gbrain` is a separate GBrain DB when GBrain is installed on that host.
- Hermes agents: per-user gateway containers plus host-managed common artifacts
  under `/var/lib/exdigm/hermes-common`.
- GBrain: host-level agent memory system under `~/.gbrain`; it is not inside the
  Django app container and is not deployed by ordinary `deploy.sh`.
- Host services: worker systemd services, cron/timers, media permissions, and
  Docker cleanup.

Before production deploy, identify which component classes are touched. A web
code change, a Hermes prompt/catalog change, and a GBrain service/config change
have different apply and validation gates.

## Current Development/Production Drift

Do not assume development and production match. Recheck before each production
deploy. On 2026-06-22 the observed state was:

- Development: `Exdigm_exdigm_app`, `Exdigm_exdigm_sse`, `Exdigm_nginx`,
  `Exdigm_exdigm_db`, two `exdigm-agent-*` containers, and active local
  GBrain services. After the Hermes Agent API surface reduction, development
  Hermes common catalog may expose 18 routes.
- Production: `Exdigm_exdigm_app`, `Exdigm_nginx`, `Exdigm_exdigm_db`, six
  `exdigm-agent-*` containers, no `~/.gbrain` installation, and an older Hermes
  common catalog was observed with 161 routes.

These are deployment facts to verify, not permanent assumptions. If a deployment
depends on a component that exists only on development, either install and verify
that component on production as an explicit host-system rollout, or prove the
production runtime does not require it.

If Agent API/Hermes work reduced or reorganized the public route surface, compare
development and production `/var/lib/exdigm/hermes-common/exdigm-agent-api-catalog.json`
route counts before and after deploy. A healthy deploy should make production
match the tested development surface, not leave the old broad catalog in place.

## GBrain Deployment Boundary

GBrain is currently a development-host memory layer used by Codex, Claude Code,
and Hermes-related tooling. It is not automatically available on production.

Known local baseline:

- CLI wrapper: `~/.gbrain/bin/gbrain_with_google_env.sh`
- HTTP MCP service: `gbrain-http.service`
- Health endpoint: `http://127.0.0.1:3131/health`
- Daily memory distillation: `gbrain-memory-distill.timer`
- DB: dedicated `gbrain` database in the shared pgvector Postgres container
- Embedding baseline: `google:gemini-embedding-001`, 768 dimensions

Production deploy rule:

- Do not make production web deploys depend on GBrain unless production has
  passed the GBrain readiness gate below.
- If a feature only needs GBrain-derived static artifacts committed into source
  or rendered into Hermes `/opt/common`, production can run without a live
  GBrain service after those artifacts are deployed.
- If a feature calls live GBrain MCP/HTTP/CLI at runtime, stop production deploy
  until GBrain is installed, configured, backed up, and verified on production.
- Existing Exdigm DB backup scripts that dump only the `exdigm` DB do not
  preserve GBrain memory. Any rebuild or migration plan must include the
  `gbrain` DB and `~/.gbrain` host files, or explicitly mark GBrain memory as
  excluded.

GBrain readiness gate:

```bash
test -d ~/.gbrain
curl -fsS --max-time 5 http://127.0.0.1:3131/health
systemctl --user is-enabled gbrain-http.service gbrain-memory-distill.timer
systemctl --user is-active gbrain-http.service gbrain-memory-distill.timer
systemctl --user list-timers gbrain-memory-distill.timer --no-pager
~/.gbrain/bin/gbrain_with_google_env.sh stats
~/.gbrain/bin/gbrain_with_google_env.sh embed --stale --dry-run
~/.gbrain/bin/gbrain_with_google_env.sh doctor --json
python3 ~/.gbrain/bin/memory_distill.py check-pending
```

Also confirm `.env` has `GEMINI_API_KEY` presence without printing the value.
If dream distillation is required, confirm `OPENROUTER_API_KEY` presence without
printing the value.

## Development Hermes Agents

The development server should run only two Hermes Telegram agent containers:

- one boss/CEO test agent
- one staff test agent

When a production DB backup is restored into development, `AgentProfile` and
`AgentCredential` rows may include production Telegram bot usernames, Telegram
user IDs, and encrypted bot tokens. Do not start all restored profiles on the
development server. Running the same Telegram bot token on development and
production at the same time can make Telegram polling unreliable and may route
real messages to the wrong server.

Before or after any Hermes-related development deploy, verify development agent
containers:

```bash
docker ps --format '{{.Names}}\t{{.Status}}\t{{.Image}}' | grep '^exdigm-agent-' || true
```

If there are more than two running `exdigm-agent-*` containers on development,
stop the extras. Prefer development-only bot tokens for the two retained
development agents. If development-only tokens are not available, do not treat
Telegram E2E validation as isolated from production.

## Start Every Deployment Task

1. `cd /home/chaconne/exdigm`
2. Run `git status --short`.
3. State:
   - allowed changes
   - forbidden changes
   - validation method
4. Confirm the current branch before acting.
5. Do not revert user changes.

## Development Deploy

Use when the user asks for "개발배포", "개발 서버에 배포", or equivalent.

Expected flow:

```text
dev branch work
  -> commit selected production-bound files
  -> scripts/exdigm_deploy.sh dev
  -> validate the Docker/Swarm deployment on the development server
```

Procedure:

1. Ensure the branch is `dev`. If not, stop and explain.
2. Review `git status --short`.
3. Stage only production-bound files unless the user explicitly says to commit all current changes.
4. Commit before deployment so the deployed version is reproducible.
5. Run:

```bash
scripts/exdigm_deploy.sh dev
```

6. Verify at minimum:

```bash
curl -k -fsSI --max-time 10 https://127.0.0.1/
docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' | rg 'Exdigm_exdigm_(db|app)|Exdigm_nginx|synco' || true
git status --short
```

7. If Agent API, Hermes prompt, menu, catalog, MCP server, onboarding, or
   profile provisioning changed, run the Hermes deployment gate:

```bash
HERMES_RESTART_AGENTS=true scripts/deploy_hermes.sh
python3 - <<'PY'
import json
from pathlib import Path
catalog = json.loads(Path('/var/lib/exdigm/hermes-common/exdigm-agent-api-catalog.json').read_text())
menu = json.loads(Path('/var/lib/exdigm/hermes-common/exdigm-agent-menu.json').read_text())
print('catalog_routes=', len(catalog.get('routes', [])))
print('menu_route_index=', len(menu.get('route_index', {})))
print('read_routes=', [r['name'] for r in catalog.get('routes', []) if r.get('read_or_write') == 'read'])
PY
docker ps --format '{{.Names}}\t{{.Status}}\t{{.Image}}' | grep '^exdigm-agent-' || true
```

8. If GBrain or memory-distillation files changed, run the GBrain readiness gate
   on development and record whether production has the same capability.
9. If UI/templates/static/common partials changed, capture a browser screenshot before reporting completion.

## Promote To Main

Use only after a committed `dev` version has been deployed and validated on the development server.

Run:

```bash
scripts/exdigm_deploy.sh promote
```

This fast-forwards local `main` to the tested `dev` commit. It must refuse dirty worktrees. If fast-forward is impossible, stop; do not invent a merge strategy.

## Production Deploy

Use when the user asks for "운영배포", "운영 서버에 배포", or equivalent.

Production deploy assumes the tested commit has already been promoted to local `main`.

Before running production deploy, compare the touched component classes against
production capabilities:

- Web-only changes may use `scripts/exdigm_deploy.sh prod` after dev validation.
- Hermes changes require production `scripts/deploy_hermes.sh` after the web
  deploy pulls the tested commit.
- GBrain-dependent runtime changes require production GBrain installation and
  readiness verification before enabling the code path.
- Do not install GBrain on production as an incidental side effect of a web
  deploy. Treat it as an explicit host-system rollout with its own backup and
  verification.

Run:

```bash
scripts/exdigm_deploy.sh prod
```

This must:

```text
local main
  -> push GitHub origin/main
  -> SSH to production
  -> production git pull --ff-only origin main
  -> production ./deploy.sh
```

Never deploy production from `dev` or a dirty worktree.

If Hermes files changed, run this on production after `scripts/exdigm_deploy.sh prod`
has pulled the tested commit:

```bash
ssh -o StrictHostKeyChecking=accept-new chaconne@115.68.224.161 \
  "cd /home/chaconne/exdigm && HERMES_RESTART_AGENTS=true scripts/deploy_hermes.sh"
```

Then verify production Hermes common artifacts and agent health:

```bash
ssh -o StrictHostKeyChecking=accept-new chaconne@115.68.224.161 \
  "python3 - <<'PY'
import json
from pathlib import Path
catalog = json.loads(Path('/var/lib/exdigm/hermes-common/exdigm-agent-api-catalog.json').read_text())
menu = json.loads(Path('/var/lib/exdigm/hermes-common/exdigm-agent-menu.json').read_text())
print('catalog_routes=', len(catalog.get('routes', [])))
print('menu_route_index=', len(menu.get('route_index', {})))
print('read_routes=', [r['name'] for r in catalog.get('routes', []) if r.get('read_or_write') == 'read'])
PY
docker ps --format '{{.Names}}\t{{.Status}}\t{{.Image}}' | grep '^exdigm-agent-' || true"
```

## Version Flow

```text
development local branch dev
        |
        | commit
        v
new dev version A
        |
        | scripts/exdigm_deploy.sh dev
        v
development Docker/Swarm runs version A for real testing
        |
        | scripts/exdigm_deploy.sh promote
        v
development local main points to version A
        |
        | scripts/exdigm_deploy.sh prod
        v
GitHub origin/main receives version A
        |
        | production server pulls origin/main
        v
production main points to version A
        |
        v
production Docker/Swarm runs version A
```

## Parity Checks

Before treating development validation as meaningful, compare development and production when relevant:

```bash
docker service ls --filter name=Exdigm --format '{{.Name}}\t{{.Image}}\t{{.Ports}}'
docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' | rg 'Exdigm_|exdigm-agent|postgres|pgvector|gbrain|synco' || true
systemctl --user is-active gbrain-http.service gbrain-memory-distill.timer 2>/dev/null || true
curl -fsS --max-time 5 http://127.0.0.1:3131/health 2>/dev/null || true
rg -n '^(POSTGRES_HOST|POSTGRES_PORT|EXDIGM_DB_PUBLISHED_PORT|DJANGO_SETTINGS_MODULE|GEMINI_API_KEY|OPENROUTER_API_KEY)=' .env | sed -E 's/(GEMINI_API_KEY|OPENROUTER_API_KEY)=.*/\1=<present>/' || true
```

Production reference command:

```bash
ssh -o StrictHostKeyChecking=accept-new chaconne@115.68.224.161 "cd /home/chaconne/exdigm && docker service ls --filter name=Exdigm --format '{{.Name}}\t{{.Image}}\t{{.Ports}}' && docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' | grep -E 'Exdigm_|exdigm-agent|postgres|pgvector|gbrain|synco' || true && test -d ~/.gbrain && echo gbrain_dir=yes || echo gbrain_dir=no; systemctl --user is-active gbrain-http.service gbrain-memory-distill.timer 2>/dev/null || true; curl -fsS --max-time 5 http://127.0.0.1:3131/health 2>/dev/null || true; grep -En '^(POSTGRES_HOST|POSTGRES_PORT|EXDIGM_DB_PUBLISHED_PORT|DJANGO_SETTINGS_MODULE|GEMINI_API_KEY|OPENROUTER_API_KEY)=' .env | sed -E 's/(GEMINI_API_KEY|OPENROUTER_API_KEY)=.*/\1=<present>/' || true"
```

If development has an extra production-class component that production does not
have, do not blindly remove it or push it. Decide whether it is a dev-only test
fixture, a new production rollout requirement, or stale drift. Document the
decision before validating production readiness.

## Worker Status

Use:

```bash
scripts/run_workers.sh status
```

The human-readable output should focus on worker, state, jobs, and drain status. Treat unusually high updater jobs as stale `FileData.is_processing` claims until proven otherwise. Investigate before releasing claims; release only the stale owner/run_id after confirming the process is dead.

## Stop Conditions

Stop and report instead of pushing or deploying when:

- The branch is not the expected branch for the requested stage.
- The worktree is dirty before promote or production deploy.
- Development and production infrastructure are not meaningfully equivalent.
- The change requires live GBrain but production has no verified GBrain service.
- Hermes prompt/catalog/API surface changed but production `deploy_hermes.sh`
  has not been planned.
- Tests or smoke checks show a real behavior failure.
- A DB cleanup or service removal would affect an unrelated system and the user has not approved it.
