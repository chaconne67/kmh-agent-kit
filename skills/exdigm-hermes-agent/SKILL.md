---
name: exdigm-hermes-agent
description: Use when changing, operating, debugging, or documenting Exdigm Hermes Telegram employee agents and their onboarding, provisioning, runtime, access, notification, migration, or offboarding boundaries.
---

# Exdigm Hermes Agent

Exdigm 직원별 Telegram Hermes의 구현·운영 규칙이다. 코드 위치는 코드 목차로
찾고, 이 스킬은 서비스 경계와 보존해야 할 계약에 집중한다.

## Start With Code Knowledge

```bash
uv run --locked python -m tools.code_knowledge code_query --query "헤르메스 에이전트"
uv run --locked python -m tools.code_knowledge code_query --query "Telegram 온보딩"
uv run --locked python -m tools.code_knowledge code_query --query "에이전트 API"
```

종료 코드 `3`이면 질의를 구체화한다. 종료 코드 `4`이면 `rg`로 현재 코드를
탐색한다. 공식 경로가 바뀌면 코드 목차와 canonical GBrain page를 함께 갱신한다.

## Official Boundaries

- 직원 1명당 `AgentProfile` 1개, 공식 Hermes container 1개, Telegram bot 1개다.
- 공식 온보딩: Exdigm 웹 → 텔레그램 관리자봇 → 관리형 봇 승인 → 독립 프로비저닝.
- 공식 업무: Hermes → 직원 container의 로컬 Exdigm MCP → Django 에이전트API.
- 공식 알림: Django → 직원 Hermes HMAC webhook → `deliver_only` → Telegram.
- Django는 직원 Telegram bot token을 읽거나 Telegram API로 직접 발송하지 않는다.
- 독립 프로비저닝 서비스만 직원 Hermes container와 profile secret 파일을 관리한다.
- 직원 비활성화·복귀·삭제는 Django의 수명주기 요청 DB에 먼저 확정한다.
- 기존 알림 배달 작업자가 독립 프로비저닝의 pause·resume·offboard HTTP 경계로
  전달하고 실패한 요청을 재시도한다.
- 기존 BotFather 입력, owner-bind, Django Docker 실행, `/agent/django`, custom image는 폐기 경로다.

## Hermes Defaults

- Nous Research 공식 Hermes image를 digest로 고정한다.
- Hermes의 기본 추론, 메모리, 도구, 개인화, 스킬 학습 기능을 유지한다.
- Exdigm 업무를 주 역할로 안내하되 기본 Hermes 기능을 막지 않는다.
- `code_execution` 비활성, bundled skill 차단, 강제 SOUL 같은 구형 제한을 되살리지 않는다.
- GBrain은 개발 환경의 선택 지식원이다. 없거나 실패해도 업무 경로는 계속 작동한다.

## Exdigm Access Policy

- Hermes의 Exdigm 탐색과 도구 사용은 기본 허용한다.
- 안내 지도는 길 찾기 힌트다. 전체 스키마나 실행 허용 목록으로 사용하지 않는다.
- 에이전트API는 직원 인증과 현재 웹 권한을 적용한다. 제한된 JSON을 Django ORM으로
  바꾸는 것을 목표 역할로 삼지 않는다.
- 인증 우회, 현재 권한 초과, 다른 직원·환경으로의 경계 이탈, 시스템 비밀값 접근,
  데이터 삭제, 시스템 훼손과 권한 상승만 기계적으로 차단한다.
- 사용자 요청 유형별 tool·route·workflow, 모델·필드·함수 allowlist와 오류별
  보정 문법을 추가하지 않는다.
- 파일·코드·DB를 탐색하는 격리 방식은 ADR-0022의 후속 grill 결정 전까지 임의로
  확정하거나 구현하지 않는다.

## Profile Preservation

- 보존: profile name, `memories/`, `workspace/`, 직원 생성 `skills/`, Hermes state.
- 교체: `config.yaml`, `SOUL.md`, 예약 `skills/exdigm-work`, `.env`.
- 제거: `.no-bundled-skills`, 구형 snapshot·fingerprint·refresh marker, stale session.
- 직원 생성 skill 전체를 지우지 않는다.
- 관리형 Gateway와 webhook 준비 완료 뒤에만 Django의 구형 bot token 필드를 비운다.
- 같은 준비 완료 뒤 구형 `hermes-config/<profile>`의 관리 secret·config 파일도 제거한다.

## References

- `references/architecture.md`: 역할과 공식 실행 경로
- `references/agent-api.md`: 네거티브 접근 경계와 현재 전환 상태
- `references/onboarding-provisioning-ops.md`: 관리형 연결·secret·프로비저닝
- `references/troubleshooting.md`: 장애 분리와 검증

## Verification

```bash
flock -E 75 -w 55 /tmp/exdigm-pytest.lock uv run --locked pytest -q \
  tests/test_agent_api_foundation.py \
  tests/test_agent_api_read.py \
  tests/test_agent_api_write.py \
  tests/test_agent_api_email.py \
  tests/test_provisioning_service.py \
  tests/accounts/test_agent_lifecycle.py \
  tests/accounts/test_telegram_connection_boundary.py \
  tests/test_telegram_connection_service.py \
  tests/test_notification_dispatch_worker.py

uv run --locked python -m tools.code_knowledge catalog_update
uv run --locked python manage.py check
```

운영 container·Telegram 검증은 사용자가 운영 작업을 요청한 경우에만 수행한다.
