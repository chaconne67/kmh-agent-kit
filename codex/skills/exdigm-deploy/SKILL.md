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

7. If UI/templates/static/common partials changed, capture a browser screenshot before reporting completion.

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
docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' | rg 'Exdigm_|postgres|pgvector|synco' || true
rg -n '^(POSTGRES_HOST|POSTGRES_PORT|EXDIGM_DB_PUBLISHED_PORT|DJANGO_SETTINGS_MODULE)=' .env || true
```

Production reference command:

```bash
ssh -o StrictHostKeyChecking=accept-new chaconne@115.68.224.161 "cd /home/chaconne/exdigm && docker service ls --filter name=Exdigm --format '{{.Name}}\t{{.Image}}\t{{.Ports}}' && docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' | grep -E 'Exdigm_|postgres|pgvector|synco' || true && grep -En '^(POSTGRES_HOST|POSTGRES_PORT|EXDIGM_DB_PUBLISHED_PORT|DJANGO_SETTINGS_MODULE)=' .env || true"
```

If development has an extra production-class component that production does not have, stop and align development to production before validating.

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
- Tests or smoke checks show a real behavior failure.
- A DB cleanup or service removal would affect an unrelated system and the user has not approved it.
