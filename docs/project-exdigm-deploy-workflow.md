# Exdigm Deploy Workflow

검색 앵커: project/exdigm-deploy-workflow, 배포, 운영, Docker stack, dev prod parity, cleanup, worker.

## Purpose

Exdigm 개발 서버 변경은 운영 반영 후보로 본다. 개발 서버에서 빠르게 검증하고, 운영 서버에서는 검증된 `main`을 pull/apply하는 대상으로 둔다.

## First Targets

- code_map topic: `배포·운영`
- Deploy scripts: `deploy/`
- Worker/service scripts: `scripts/`
- Docker/stack files
- Hermes recipe refresh and fleet operations

## Reuse Rules

- 운영 서버에서 개발 작업, 반복 테스트, DB 실험을 하지 않는다.
- 개발 전용 설정은 운영 반영 대상과 분리한다.
- code, migration, template, static, deploy script, worker script 변경은 운영 반영 후보로 본다.
- 배포 변경 뒤에는 focused smoke/health check를 남긴다.

## Validation

- 해당 deploy skill이나 deploy script의 dry-run/check 명령
- Docker stack service 상태
- 필요한 worker/timer/service 상태
