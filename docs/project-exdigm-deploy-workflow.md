# Exdigm Deploy Workflow

검색 앵커: project/exdigm-deploy-workflow, 배포, 운영, Docker stack, dev prod parity, cleanup, worker, GBrain, gbrain-http, memory distillation, Hermes deploy, agent memory.

## Purpose

Exdigm 개발 서버 변경은 운영 반영 후보로 본다. 개발 서버에서 빠르게 검증하고, 운영 서버에서는 검증된 `main`을 pull/apply하는 대상으로 둔다.

## First Targets

- code_map topic: `배포·운영`
- Deploy scripts: `deploy/`
- Worker/service scripts: `scripts/`
- Docker/stack files
- Hermes recipe refresh and fleet operations
- GBrain host-level services and data: `~/.gbrain`, `gbrain-http.service`, `gbrain-memory-distill.timer`, dedicated `gbrain` Postgres DB, agent tokens/config

## Reuse Rules

- 운영 서버에서 개발 작업, 반복 테스트, DB 실험을 하지 않는다.
- 개발 전용 설정은 운영 반영 대상과 분리한다.
- code, migration, template, static, deploy script, worker script 변경은 운영 반영 후보로 본다.
- 배포 변경 뒤에는 focused smoke/health check를 남긴다.

## System Components

Exdigm 배포는 Django 웹 이미지만이 아니다. 작업마다 어떤 component class가 바뀌는지 먼저 구분한다.

- Web stack: Django app, optional SSE, nginx, static/media, migrations, workers.
- Database: shared pgvector Postgres container. `exdigm` DB와 GBrain용 `gbrain` DB는 별도다.
- Hermes: per-user gateway containers and `/var/lib/exdigm/hermes-common` common artifacts.
- GBrain: host-level memory layer under `~/.gbrain`; ordinary `deploy.sh` 대상이 아니다.
- Host services: worker systemd services, cron/timers, media permissions, Docker cleanup.

## Current Dev/Prod Drift / 2026-06-22

배포 전에 항상 다시 확인한다. 2026-06-22 read-only 점검 기준:

- Development: `Exdigm_exdigm_app`, `Exdigm_exdigm_sse`, `Exdigm_nginx`, `Exdigm_exdigm_db`, two `exdigm-agent-*` containers, active `gbrain-http.service`, active `gbrain-memory-distill.timer`. After the Hermes Agent API surface reduction, development Hermes common catalog may expose 18 routes.
- Production: `Exdigm_exdigm_app`, `Exdigm_nginx`, `Exdigm_exdigm_db`, six `exdigm-agent-*` containers, no `~/.gbrain`, inactive/missing GBrain user services. An older production Hermes common catalog was observed with 161 routes.

이 차이는 영구 사실이 아니라 배포 게이트다. 운영에 없는 component에 의존하는 변경이면 운영에 해당 component를 명시적으로 설치/검증하거나, 운영 runtime이 그것을 필요로 하지 않음을 증명한다.

Agent API/Hermes 공개 route surface를 줄이거나 재구성한 작업은 개발과 운영의 `/var/lib/exdigm/hermes-common/exdigm-agent-api-catalog.json` route count를 배포 전후로 비교한다. 정상 배포는 운영 common artifact가 검증된 개발 surface와 일치해야 한다.

## GBrain Deployment Boundary

2026-06-22 점검 기준, GBrain은 Exdigm 앱 컨테이너 내부 기능이 아니라 호스트 레벨 공용 시스템이다.

- HTTP MCP service: `gbrain-http.service`, `http://127.0.0.1:3131/mcp`, health `http://127.0.0.1:3131/health`.
- Daily memory distillation: `gbrain-memory-distill.timer` -> `memory_distill.py generate`, default 03:30 KST.
- Data: dedicated `gbrain` DB in the existing Exdigm pgvector Postgres container, plus host files under `~/.gbrain`.
- Direct CLI calls must use `~/.gbrain/bin/gbrain_with_google_env.sh` so Google embedding env is present and unrelated Exdigm DB/OpenAI/OpenRouter env does not leak.

Deployment implication:

- Do not hide GBrain inside ordinary `deploy.sh` web deploy semantics. Treat it as a separate host system gate adjacent to web, worker, Hermes, and cron/timer gates.
- Existing Exdigm DB backup scripts that dump only `POSTGRES_DB=exdigm` do not preserve the `gbrain` DB. Any server rebuild, dev/prod parity setup, or backup/restore plan must explicitly include `gbrain` DB backup/restore or document that GBrain memory is intentionally excluded.
- GBrain verification should include service health, user timer status, embedding config/stale chunks, and safe file permissions for `~/.gbrain` tokens/config/reports.
- GBrain service changes are code/config/service changes and require the same post-change review discipline as Exdigm deploy scripts.
- If a production feature only uses GBrain-derived static source or Hermes common artifacts, production can run without live GBrain after those artifacts are deployed.
- If a production feature calls live GBrain MCP/HTTP/CLI, stop until production GBrain is installed and passes readiness checks.

## Hermes Deploy Boundary

`scripts/exdigm_deploy.sh prod` runs the web deploy and workers. It does not automatically refresh production Hermes common artifacts.

When Agent API, Hermes prompt, menu, catalog, MCP server, onboarding, or profile provisioning changed:

1. Deploy and validate on development.
2. Run `HERMES_RESTART_AGENTS=true scripts/deploy_hermes.sh` on development.
3. Promote the tested commit to `main`.
4. Run `scripts/exdigm_deploy.sh prod`.
5. Run production `HERMES_RESTART_AGENTS=true scripts/deploy_hermes.sh`.
6. Verify production `/var/lib/exdigm/hermes-common` catalog/menu route counts and `exdigm-agent-*` health.

## Validation

- 해당 deploy skill이나 deploy script의 dry-run/check 명령
- Docker stack service 상태
- 필요한 worker/timer/service 상태
- Hermes common artifact route count and agent health when Hermes changed
- GBrain checks when deployment touches host/system setup or server rebuild:
  - `curl -fsS --max-time 5 http://127.0.0.1:3131/health`
  - `systemctl --user status gbrain-http.service gbrain-memory-distill.timer --no-pager`
  - `~/.gbrain/bin/gbrain_with_google_env.sh stats`
  - `~/.gbrain/bin/gbrain_with_google_env.sh embed --stale --dry-run`
  - Confirm both `exdigm` and `gbrain` DBs exist if the shared pgvector container is restored or migrated.
