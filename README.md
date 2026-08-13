# KMH Agent Kit

## 개요

KMH Agent Kit은 여러 서버의 Codex·Claude Code가 같은 스킬, 작업 규칙, GBrain 기억 구조를 사용하게 만드는 저장소입니다.

서버 이름 하나로 설치가 끝납니다.

```bash
~/kmh-agent-kit/install.sh rndlog
```

이 한 줄이 다음 작업을 순서대로 수행합니다.

1. 공용 스킬과 전역 지침 설치
2. 서버에 맞는 GBrain 카드 설치
3. 원격 서버라면 중앙 GBrain SSH 프록시 연결
4. 등록된 프로젝트 프로필 자동 연결
5. 카드와 GBrain 연결 실제 검증

신규 에이전트도 한 줄로 추가할 수 있습니다.

```bash
~/kmh-agent-kit/install.sh --new analytics
```

이 명령은 중앙 GBrain 공간·접근 정책·범용 카드까지 만들고 현재 서버에 설치합니다.

## 퀵 설치 방법

### 저장소가 이미 있는 서버

| 서버 | 한 줄 명령 |
|---|---|
| 중앙 DB·GBrain `49.247.45.243` | `~/kmh-agent-kit/install.sh main` |
| FundKeeper `49.247.38.186` | `~/kmh-agent-kit/install.sh fundkeeper` |
| Rndlog `49.247.207.147` | `~/kmh-agent-kit/install.sh rndlog` |
| Ceoloan `49.247.205.170` | `~/kmh-agent-kit/install.sh ceoloan` |
| Judy WSL | `~/kmh-agent-kit/install.sh judy` |

### 저장소도 없는 새 서버

서버에 맞는 한 줄만 실행합니다.

중앙 DB·GBrain:

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh main
```

FundKeeper:

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh fundkeeper
```

Rndlog:

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh rndlog
```

Ceoloan:

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh ceoloan
```

### 신규 에이전트 추가

예를 들어 `analytics`라는 새 에이전트를 추가할 때:

```bash
~/kmh-agent-kit/install.sh --new analytics
```

실제 변경 전에 생성 내용을 확인하려면:

```bash
~/kmh-agent-kit/install.sh --new analytics --dry-run
```

신규 이름은 영문 소문자·숫자·중간 하이픈으로 된 1~32자를 사용합니다. 원격 서버에서 실행할 때는 중앙 서버 `49.247.45.243`로 SSH 접속할 수 있어야 합니다.

## 그 외

### 가능한 명령

| 명령 | 용도 |
|---|---|
| `./install.sh main` | 중앙 DB·GBrain 서버 설치 |
| `./install.sh fundkeeper` | FundKeeper 서버 설치 |
| `./install.sh rndlog` | Rndlog 서버 설치 |
| `./install.sh ceoloan` | Ceoloan 서버 설치 |
| `./install.sh judy` | Judy WSL 설치 |
| `./install.sh --new analytics` | 신규 공간·정책·카드 생성 후 설치 |
| `./install.sh --new analytics --dry-run` | 신규 생성 내용을 변경 없이 미리 확인 |
| `./install.sh` | GBrain 카드 없이 공용 스킬·전역 지침만 설치 |
| `./install.sh --project ~/exdigm exdigm` | 프로젝트 프로필만 별도로 연결 |
| `./install.sh --gbrain rndlog` | 이전 명령 호환용; 이제 `./install.sh rndlog`와 동일 |
| `./install.sh --help` | 설치 가능한 명령 표시 |

`--register-agent`는 원격 서버의 `--new`가 중앙 서버를 호출할 때만 쓰는 내부 옵션입니다. 직접 실행할 필요가 없습니다.

### 신규 에이전트 생성 원리

`./install.sh --new analytics`는 다음 경로 하나만 사용합니다.

1. `gbrain-cards/analytics.md` 범용 카드 생성
2. 중앙 GBrain에 `analytics` 소스 생성
3. 중앙 기본 소스를 즉시 `default`로 되돌리고 공용 조회 검증
4. 중앙 정책에 `agents/analytics/private` 읽기·쓰기 경계 등록
5. 현재 서버에 공용 자산·카드·`gbrain-analytics` 래퍼 설치
6. 실제 정책 조회로 연결 검증

같은 이름이 이미 있으면 기존 공간·정책·카드를 덮어쓰지 않고 그대로 사용합니다. 정책 값이 예상과 다르면 자동 수정하지 않고 중단합니다.

새 카드는 저장소의 신규 파일로 남습니다. 다른 서버도 사용하게 하려면 검토 후 커밋·push합니다.

### 서버별 자동 프로젝트 연결

| 에이전트 | 자동 연결되는 프로젝트 프로필 |
|---|---|
| `main` | `~/exdigm`의 `exdigm` 프로필 |
| `fundkeeper` | `~/fundkeeper`의 `fundkeeper` 프로필 |
| 그 외 | 같은 이름의 프로젝트 폴더와 프로필이 모두 있을 때 자동 연결 |

Rndlog와 Ceoloan은 별도 프로젝트 프로필이 없으므로 전역 자산과 GBrain 카드까지만 설치합니다.

### 작동 원리

| 설치 대상 | 저장소 원본 | 실제 사용 위치 |
|---|---|---|
| 공용 스킬 | `skills/common/` | `~/.claude/skills/`, `~/.codex/skills/` |
| 전역 지침 | `claude/CLAUDE.md`, `codex/AGENTS.md` | 각 도구의 전역 지침 위치 |
| 프로젝트 스킬 | `projects/` | 프로젝트의 `.claude/skills/`, `.codex/skills/` |
| GBrain 카드 | `gbrain-cards/` | `~/.gbrain-agent.md` |
| 원격 GBrain 프록시 | `gbrain/bin/gbrain-remote-proxy` | `~/.local/bin/gbrain-rndlog` 같은 이름 |

Linux에서는 저장소 원본과 실제 사용 위치를 심볼릭 링크로 연결합니다. 기존 일반 파일은 삭제하지 않고 `~/.kmh-agent-kit-backup-날짜-시각/`에 보존합니다.

### 업데이트

기존 서버는 서버 이름을 포함한 한 줄로 업데이트와 재설치를 함께 수행합니다.

Rndlog:

```bash
git -C ~/kmh-agent-kit pull --ff-only && ~/kmh-agent-kit/install.sh rndlog
```

Ceoloan:

```bash
git -C ~/kmh-agent-kit pull --ff-only && ~/kmh-agent-kit/install.sh ceoloan
```

### 설치 확인

```bash
python3 ~/kmh-agent-kit/scripts/check-skill-deps.py
readlink -f ~/.gbrain-agent.md
```

Rndlog 연결 확인:

```bash
gbrain-rndlog policy
```

중앙 GBrain 확인:

```bash
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
```

### Windows

Windows는 기존 PowerShell 설치기를 사용합니다.

Gram17:

```powershell
git clone https://github.com/chaconne67/kmh-agent-kit.git $env:USERPROFILE\kmh-agent-kit
cd $env:USERPROFILE\kmh-agent-kit
.\install.ps1
.\install.ps1 -Gbrain gram17
```

Venture:

```powershell
git clone https://github.com/chaconne67/kmh-agent-kit.git $env:USERPROFILE\kmh-agent-kit
cd $env:USERPROFILE\kmh-agent-kit
.\install.ps1
.\install.ps1 -Gbrain venture
```

Windows는 junction과 하드링크를 사용합니다. Linux용 GBrain SSH 프록시와 systemd 서비스는 설치하지 않습니다.

Exdigm 운영 서버 `115.68.224.161`은 현재 이 저장소의 설치 대상이 아닙니다. 그 서버에서는 위 설치 명령을 실행하지 않습니다.

### 공용 스킬과 프로젝트 스킬

| 구분 | 원본 | 연결 범위 |
|---|---|---|
| 공용 스킬 | `skills/common/` | Claude·Codex 전역 |
| 도메인 스킬 | `skills/domains/` | 해당 프로젝트 프로필만 |

도메인 스킬을 전역에 연결하면 다른 프로젝트에서도 잘못 발동할 수 있습니다. `scripts/check-skill-deps.py`가 이 오류를 검사합니다.

### 저장소에 넣지 않는 것

- API 키, 비밀번호, OAuth 토큰
- GBrain 데이터베이스와 백업 덤프
- 외부에서 받은 타사 스킬 원본
- Exdigm·Rndlog·Ceoloan 같은 실제 서비스 코드
- 한 서버·한 프로젝트에서만 쓰는 로컬 전용 자산

### 저장소 구조

```text
skills/common/                 공용 스킬 원본
skills/domains/                도메인 전용 스킬 원본
claude/                        Claude Code 전역 프로필과 지침
codex/                         Codex 전역 프로필과 지침
projects/                      프로젝트별 스킬 프로필
gbrain-cards/                  에이전트별 GBrain 카드
gbrain/                        GBrain 래퍼와 Linux 서비스 파일
scripts/                       구조 검사와 스킬 연결 도구
docs/                          상세 운영 문서
```

상세한 신규 서버 점검은 [New Server Onboarding](docs/onboarding-new-server.md), 스킬 관리 방법은 [Skill Management](docs/skill-management.md), 장애 해결은 [Troubleshooting](docs/troubleshooting.md)을 봅니다.
