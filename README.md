# KMH Agent Kit

KMH Agent Kit은 Codex, Claude Code, Hermes 같은 여러 에이전트가 같은 스킬, 같은 작업 규칙, 같은 장기 기억을 공유하도록 만드는 개인 에이전트 운영 키트입니다.

목표는 사용자가 같은 설명을 반복하지 않게 하는 것입니다. 에이전트는 작업 전에 GBrain을 조회하고, 작업 중 발견한 지속 가능한 규칙과 교훈을 GBrain에 저장하며, 코드 작업 후에는 코드 리뷰 루프를 실행합니다.

## 구조 (단일 원본 + 심링크 프로필)

```
skills/<이름>/            스킬 단일 원본 (도구 중립). 편집은 여기서만 일어난다.
claude/skills/<이름>      Claude Code 전역 프로필 — ../../skills/<이름> 상대 심링크
claude/CLAUDE.md          Claude Code 전역 지침 원본
codex/skills/<이름>       Codex 전역 프로필 — 상대 심링크
codex/AGENTS.md           Codex 전역 지침 원본
projects/<프로젝트>/       프로젝트 프로필: skills/ 심링크 + CLAUDE.md·AGENTS.md 원본
manifests/skills.json     스킬 간 의존관계(depends_on)만 보관 — 배치 정본은 프로필 심링크
gbrain/                   GBrain 실행 래퍼·systemd 유닛 (복사식 설치)
docs/                     온보딩·운영 문서, Exdigm 지식 문서
scripts/                  구조 검증 스크립트
```

설치(`install.sh`)는 live 위치(`~/.claude/skills/*`, `~/.codex/skills/*`, `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`)를 이 레포의 프로필로 **심볼릭 링크**합니다. 그 후에는:

- live에서 스킬·지침을 편집하면 링크를 통해 레포 작업트리가 직접 바뀐다 → `git status`에 바로 보인다.
- 동기화는 `git commit / push / pull`이 전부다. 별도 동기화 스크립트가 없다.
- git은 레포 안의 상대 심링크를 그대로 커밋·복원하므로 clone/pull만으로 프로필이 재현된다.

## Quick Start

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
cd ~/kmh-agent-kit
./install.sh                      # 전역 연결 (claude + codex + gbrain)
./install.sh --project ~/exdigm exdigm   # 프로젝트 프로필 연결
```

설치 후 확인:

```bash
python3 ~/kmh-agent-kit/scripts/check-skill-deps.py
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
```

## 일상 관리

| 작업 | 방법 |
|---|---|
| 스킬·지침 수정 | live에서 그대로 편집 → `git commit && git push` |
| 다른 서버 반영 | `git pull` (즉시 live 반영, 재설치 불필요) |
| 새 스킬 추가 | `skills/<이름>/SKILL.md` 작성 → 프로필에 `ln -s` → 커밋 → 다른 서버는 `git pull && ./install.sh` |
| 스킬 삭제 | `git rm` (skills/ + 프로필 링크) → 다른 서버는 `git pull && ./install.sh` |
| 새 프로젝트 적용 | `docs/skill-management.md`의 프로젝트 온보딩 절차 (의존성 포함 선별 설치) |

## What Is Not Included

- API key, DB password, OAuth token 같은 비밀값
- 외부에서 가져온 타사 스킬 원본
- 프로젝트 코드, 도메인 전용 로컬 스킬(예: exdigm-deploy)
- GBrain 데이터베이스 덤프

## Core Rules

- 바퀴를 재발명하지 않습니다. GBrain 자체 기능, 기존 스킬, 기존 프로젝트 코드를 먼저 찾고 재사용합니다.
- 새 코드는 없으면 동작하지 않는 경우에만 작성합니다.
- 임시방편보다 근본 원인을 해결합니다.
- 코드·스크립트·설정·서비스·schema·자동화 변경 후에는 코드 리뷰를 실행합니다.
