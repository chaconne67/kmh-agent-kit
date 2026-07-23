# Troubleshooting And Verification

## Debug Order

1. Django 연결 상태와 최신 `TelegramConnectionAttempt`를 확인한다.
2. Telegram 연결 API의 관리자봇 update·관리형 봇 승인 상태를 확인한다.
3. 프로비저닝 job 상태를 확인한다. job DB나 로그에서 secret을 출력하지 않는다.
4. 직원 container가 실행 중인지 확인한다.
5. container 내부 `http://127.0.0.1:8644/health`를 확인한다.
6. profile의 `config.yaml`, `SOUL.md`, `skills/exdigm-work/SKILL.md`를 확인한다.
7. 로컬 Exdigm MCP의 현재 등록 도구를 확인한다.
8. Django `AgentAuditLog`에서 실제 에이전트API 오류를 확인한다.

## Symptom Table

| 증상 | 먼저 볼 경계 |
|---|---|
| 연결 버튼 뒤 진행 없음 | Django 연결값 → 관리자봇 update |
| 승인 뒤 준비 중 고정 | Telegram 연결 API → 프로비저닝 job |
| container 실행이나 연결 실패 | profile `.env` mode, 공식 image, network |
| Telegram 대화는 되나 업무 실패 | 로컬 Exdigm MCP → Django 에이전트API |
| 알림만 안 옴 | `Exdigm_net` 안의 Django 알림 작업자 → Hermes HMAC deliver-only |
| 퇴사자 bot이 계속 응답 | `AgentLifecycleRequest` pending/error → 프로비저닝 offboard |
| 재활성화 뒤 다시 멈춤 | 같은 profile의 이전 pending 요청이 앞 순서로 남았는지 확인 |
| 비활성 직원의 신규 bot이 응답 | 프로비저닝 desired-state 재확인과 pause 결과 확인 |
| 구형 답변·제한 지속 | stale session·구형 marker 정리 |
| 개발에서 GBrain만 실패 | 선택 연결로 격리됐는지 확인 |

## Notification Checks

- Django source가 `get_bot_token()`이나 `api.telegram.org`를 호출하지 않아야 한다.
- webhook body는 UTF-8 compact JSON이다.
- signature는 `HMAC-SHA256(secret, "<timestamp>.<body>")` hex다.
- `X-Webhook-Signature-V2`, `X-Webhook-Timestamp`, `X-Request-ID`를 보낸다.
- `delivered`와 `duplicate`만 성공으로 처리한다.
- 알림 작업자가 host systemd가 아니라 app stack의
  `exdigm_notification_dispatcher` service인지 확인한다.
- 구형 `exdigm-notification-dispatcher.service`가 active이면 새 stack 배포의
  retirement 단계가 실행됐는지 확인한다.
- 직원 Hermes webhook 포트는 호스트에 공개하지 않는다.

## Focused Verification

```bash
flock -E 75 -w 55 /tmp/exdigm-pytest.lock uv run --locked pytest -q \
  tests/test_provisioning_service.py \
  tests/accounts/test_agent_lifecycle.py \
  tests/accounts/test_telegram_connection_boundary.py \
  tests/test_telegram_connection_service.py \
  tests/test_agent_api_foundation.py \
  tests/test_agent_api_read.py \
  tests/test_agent_api_write.py \
  tests/test_agent_api_email.py \
  tests/test_notification_dispatch.py \
  tests/test_notification_dispatch_worker.py

uv run --locked python -m tools.code_knowledge catalog_update
uv run --locked python manage.py check
```

## Live Checks

운영 작업을 요청받은 경우에만 실행한다. token·key·webhook secret은 출력하지 않는다.

```bash
docker ps --format '{{.Names}} {{.Image}} {{.Status}}'
docker inspect -f '{{.State.Running}}' exdigm-agent-<profile-name>
docker exec exdigm-agent-<profile-name> /opt/hermes/.venv/bin/python -c \
  'import urllib.request; print(urllib.request.urlopen("http://127.0.0.1:8644/health", timeout=2).read().decode())'
```
