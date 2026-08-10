# KMH Agent Kit

KMH Agent Kit은 Codex, Claude Code, Hermes 같은 여러 에이전트가 같은 스킬, 같은 작업 규칙, 같은 장기 기억을 공유하도록 만드는 개인 에이전트 운영 키트입니다.

목표는 사용자가 같은 설명을 반복하지 않게 하는 것입니다. 에이전트는 작업 전에 GBrain을 조회하고, 작업 중 발견한 지속 가능한 규칙과 교훈을 GBrain에 저장하며, 코드 작업 후에는 코드 리뷰 루프를 실행합니다.

## 구조 (단일 원본 + 심링크 프로필)

```
skills/common/<이름>/           공용 스킬 단일 원본 (도구·도메인 중립)
skills/domains/<도메인>/<이름>/  도메인 전용 스킬 원본 (exdigm, fundkeeper, testbed)
claude/skills/<이름>      Claude Code 전역 프로필 — ../../skills/common/<이름> 상대 심링크
claude/CLAUDE.md          Claude Code 전역 지침 원본
codex/skills/<이름>       Codex 전역 프로필 — 상대 심링크
codex/AGENTS.md           Codex 전역 지침 원본
projects/<프로젝트>/       프로젝트 프로필: 도메인 스킬 심링크 + 프로젝트 지침 원본
gbrain-cards/<에이전트>.md  에이전트별 GBrain 사용 규칙 카드 (~/.gbrain-agent.md로 링크)
manifests/skills.json     스킬 간 의존관계(depends_on)만 보관 — 배치 정본은 프로필 심링크
gbrain/                   GBrain 실행 래퍼·gbrain-agent 공간 래퍼·systemd 유닛 (복사식 설치)
docs/                     온보딩·키트 운영 문서 (프로젝트 지식 문서는 각 프로젝트 폴더에)
scripts/                  구조 검증·프로필 링크 스크립트
```

## 공용 / 도메인 구분

스킬은 **원본 위치로 분류하고, 발동 범위는 프로필로 정한다.** 두 축을 분리해 두면 "무엇인지"와 "어디서 뜨는지"를 따로 바꿀 수 있다.

| | 원본 | 전역 프로필 | 프로젝트 프로필 |
|---|---|---|---|
| 공용 스킬 | `skills/common/<이름>` | O — **claude·codex 양쪽 모두** | 보통 불필요 |
| 도메인 스킬 | `skills/domains/<도메인>/<이름>` | **금지** | O (그 프로젝트에서만 발동) |

공용 스킬은 도구를 가리지 않는다는 뜻이므로 **claude·codex 전역 프로필에 모두 연결한다.** 한쪽에만 걸면 같은 작업이 도구에 따라 다른 규칙으로 처리된다. 도구 기본 기능과 이름이 겹치는 스킬(`code-review` 등)도 키트 원본을 연결한다 — 키트가 그 이름의 정본이다.

도메인 스킬을 전역 프로필에 두면 `scripts/check-skill-deps.py`가 오류로 막는다. `scripts/link-skill.py`도 같은 규칙을 적용해 잘못된 배치를 애초에 만들지 않는다.

현재 도메인: `exdigm`(data-extraction, resume-evolution-loop), `fundkeeper`(fundkeeper, fundkeeper-deploy), `testbed`(testbed-base, testbed-etf, testbed-algo-report, testbed-rebal-report).

도메인 스킬은 프로젝트 프로필을 연결한 폴더에서만 뜨므로, **그 도메인 작업을 하는 폴더에 프로필을 연결해야 한다**:

```bash
./install.sh --project ~/<프로젝트> <도메인명>            # Linux
.\install.ps1 -Project <경로> -ProfileName <도메인명>     # Windows
```

설치(`install.sh`, Windows는 `install.ps1`)는 live 위치(`~/.claude/skills/*`, `~/.codex/skills/*`, `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`)를 이 레포의 프로필로 **심볼릭 링크**합니다. 그 후에는:

- live에서 스킬·지침을 편집하면 링크를 통해 레포 작업트리가 직접 바뀐다 → `git status`에 바로 보인다.
- 동기화는 `git commit / push / pull`이 전부다. 별도 동기화 스크립트가 없다.
- git은 레포 안의 상대 심링크를 그대로 커밋·복원하므로 clone/pull만으로 프로필이 재현된다.

## Quick Start (Linux / macOS)

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
cd ~/kmh-agent-kit
./install.sh                      # 전역 연결 (claude + codex + gbrain)
./install.sh --project ~/<프로젝트> <프로필명>   # 프로젝트 프로필 연결 (프로필이 있을 때만)
./install.sh --gbrain <에이전트>          # GBrain 카드 연결 (예: main, rndlog, judy)
```

공유 지침의 GBrain 규칙은 `~/.gbrain-agent.md` 카드 하나를 참조한다. 카드를 연결하지 않은 서버에서는 에이전트가 GBrain 규칙 전체를 건너뛴다.

설치 후 확인:

```bash
python3 ~/kmh-agent-kit/scripts/check-skill-deps.py
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
```

## Quick Start (Windows)

```powershell
git clone https://github.com/chaconne67/kmh-agent-kit.git $env:USERPROFILE\kmh-agent-kit
cd $env:USERPROFILE\kmh-agent-kit
.\install.ps1                                        # 전역 연결 (claude + codex)
.\install.ps1 -Project <경로> -ProfileName <프로필명>  # 프로젝트 프로필 연결
.\install.ps1 -Gbrain <에이전트>                       # GBrain 카드 연결
```

`install.sh`는 bash·systemd·POSIX 심링크를 전제하므로 Windows에서는 `install.ps1`을 쓴다. 결과는 같고 다음 세 가지만 다르다:

- **링크 방식** — Windows 심링크 생성은 관리자 권한이 필요해서, 디렉토리는 junction, 파일은 하드링크로 연결한다. 권한 없이 만들 수 있고 live에서 편집하면 레포 작업트리가 바뀌는 동작은 동일하다.
- **프로필 항목 해석** — 개발자 모드가 꺼진 Windows는 git이 `core.symlinks=false`로 clone해서 `claude/skills/<이름>`이 링크가 아니라 대상 경로(`../../skills/<이름>`)만 담긴 일반 파일이 된다. 설치기와 `check-skill-deps.py`는 이 표현도 링크로 인정하므로 개발자 모드 없이 그대로 설치·검증된다.
- **GBrain 런타임** — bash 래퍼와 systemd 유닛은 Linux 전용이라 건너뛴다. GBrain 규칙 카드(`-Gbrain`)는 Windows에서도 연결된다.

설치 후 확인:

```powershell
python $env:USERPROFILE\kmh-agent-kit\scripts\check-skill-deps.py
```

기존 파일은 덮어쓰지 않고 `~\.kmh-agent-kit-backup-<타임스탬프>\`로 옮긴 뒤 링크를 건다.

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
- 프로젝트 코드, 도메인 전용 자산 — 특정 프로젝트에서만 쓰는 스킬·지침·문서는 그 프로젝트 폴더의 로컬 실파일로 둔다 (예: exdigm의 `.claude/skills/`·`.claude/agent-docs/`, exdigm-deploy 스킬)
- GBrain 데이터베이스 덤프

## Core Rules

- 바퀴를 재발명하지 않습니다. GBrain 자체 기능, 기존 스킬, 기존 프로젝트 코드를 먼저 찾고 재사용합니다.
- 새 코드는 없으면 동작하지 않는 경우에만 작성합니다.
- 임시방편보다 근본 원인을 해결합니다.
- 코드·스크립트·설정·서비스·schema·자동화 변경 후에는 코드 리뷰를 실행합니다.
