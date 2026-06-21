# KMH Agent Kit

KMH Agent Kit은 Codex, Claude Code, Hermes 같은 여러 에이전트가 같은 장기 기억과 작업 규칙을 공유하도록 만드는 개인 에이전트 운영 키트입니다.

목표는 사용자가 같은 설명을 반복하지 않게 하는 것입니다. 에이전트는 작업 전에 GBrain을 조회하고, 작업 중 발견한 지속 가능한 규칙과 교훈을 GBrain에 저장하며, 코드 작업 후에는 코드 리뷰 루프를 실행합니다.

## Quick Start

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
cd ~/kmh-agent-kit
./install.sh
```

설치 후 확인:

```bash
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
python3 ~/.gbrain/bin/memory_distill.py check-pending
python3 ~/kmh-agent-kit/scripts/check-skill-deps.py
```

## What Is Included

- `codex/AGENTS.md`: 최소 글로벌 부트스트랩 지침
- `codex/skills/`: 사용자 커스텀 Codex 스킬
- `gbrain/bin/`: GBrain 실행 래퍼와 일일 memory distillation 스크립트
- `gbrain/systemd/`: GBrain HTTP MCP 서버와 일일 distillation timer
- `manifests/`: 커스텀 스킬과 베이스 스킬 의존관계
- `docs/`: 새 서버 온보딩, GBrain 운영 방식, 트러블슈팅
- `docs/exdigm-gbrain-knowledge-base.md`: Exdigm 프로젝트 지식 베이스와 code_map 연계 규칙

## What Is Not Included

- API key, DB password, OAuth token 같은 비밀값
- 외부에서 가져온 타사 스킬 원본
- Exdigm 프로젝트 코드
- GBrain 데이터베이스 덤프

## Core Rules

- 바퀴를 재발명하지 않습니다. GBrain 자체 기능, 기존 스킬, 기존 프로젝트 코드를 먼저 찾고 재사용합니다.
- 새 코드는 없으면 동작하지 않는 경우에만 작성합니다.
- 임시방편보다 근본 원인을 해결합니다.
- 문제 해결은 규모에 따라 3 Whys 또는 5 Whys를 사용하고, 현상과 원인을 구분합니다.
- 코드·스크립트·설정·서비스·schema·자동화 변경 후에는 `code-review-loop`를 실행합니다.
