# New Server Onboarding

이 문서는 아무 설명 없이 새 서버에 온 에이전트가 `kmh-agent-kit`만 보고 설치를 진행하기 위한 순서입니다.

## 1. Local Resources First

먼저 현재 접근 가능한 자원을 확인합니다.

```bash
ls -la ~
ls -la ~/.codex ~/.gbrain 2>/dev/null || true
find ~/.codex/skills -maxdepth 2 -name SKILL.md -print 2>/dev/null | sort
```

Exdigm 서버라면 `/home/chaconne/exdigm/.env`에 `GEMINI_API_KEY`와 필요 시 `OPENROUTER_API_KEY`가 있어야 합니다. 키 값은 출력하지 않습니다.

## 2. Install Runtime

GBrain CLI는 Bun 기반입니다.

```bash
command -v unzip || sudo apt-get update && sudo apt-get install -y unzip
command -v bun || curl -fsSL https://bun.sh/install | bash
```

## 3. Install Kit

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
cd ~/kmh-agent-kit
./install.sh
```

`install.sh`는 기존 파일을 덮기 전에 `.backup-YYYYmmdd-HHMMSS` 백업을 남깁니다.

## 4. Configure GBrain

Postgres/pgvector가 이미 있으면 새 DB를 만들지 말고 기존 컨테이너와 DB를 먼저 확인합니다.

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
~/.gbrain/bin/gbrain_with_google_env.sh stats
~/.gbrain/bin/gbrain_with_google_env.sh embed --stale --dry-run
```

임베딩은 `google:gemini-embedding-001`, 768 dimensions를 기준으로 합니다. Distillation 모델은 기본값으로 OpenRouter의 Gemini 모델을 사용하지만 `GBRAIN_DREAM_MODEL`로 바꿀 수 있습니다.

## 5. Enable Services

```bash
systemctl --user daemon-reload
systemctl --user enable --now gbrain-http.service
systemctl --user enable --now gbrain-memory-distill.timer
systemctl --user status gbrain-http.service --no-pager
systemctl --user list-timers gbrain-memory-distill.timer --no-pager
```

## 6. Agent Startup Check

새 세션 시작 시 에이전트는 다음을 수행합니다.

```bash
python3 ~/.gbrain/bin/memory_distill.py check-pending
~/.gbrain/bin/gbrain_with_google_env.sh query "agent operating protocol current project work rules" --no-expand
```

미확인 리포트가 있고 오늘 아직 보고하지 않았다면 사용자에게 리뷰 여부를 묻습니다.
