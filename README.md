# KMH Agent Kit

## 개요

KMH Agent Kit은 여러 서버와 프로젝트의 Codex·Claude Code에 공용 스킬과 작업 규칙을 설치하고, 프로젝트 역할별 GBrain 공간을 연결하는 저장소입니다.

설치 명령에 넣는 값은 장비의 호스트명이 아니라 **등록 이름**입니다. 등록 이름이 사용할 GBrain 공간·접근 정책·카드를 결정합니다.

먼저 현재 상황을 구분합니다.

| 상황 | 사용할 설치 방식 |
|---|---|
| 새로운 프로젝트 역할을 처음 등록 | `--new`로 공간·정책·카드까지 생성 |
| 이미 등록된 역할을 새 장비에 설치하거나 재설치 | 아래 서버별 표의 기존 등록 이름 사용 |

경계가 헷갈릴 때는 다음 두 사례로 판단합니다.

- `abc_project` 역할 자체가 처음이면 `abc-project`를 `--new`로 등록합니다.
- `abc-project`가 이미 등록되고 카드가 저장소에 반영된 뒤 장비만 추가한다면 `./install.sh abc-project`를 사용합니다.

GBrain 등록 이름은 영문 소문자·숫자·중간 하이픈으로 된 1~32자입니다. 밑줄은 허용되지 않으므로 `abc_project`의 등록 이름은 `abc-project`입니다.

최초 설치가 끝난 뒤에는 서버 이름을 다시 입력하지 않습니다.

```bash
kitpull
kitpush
```

## 퀵 설치 방법

### 새로운 `abc_project` 역할을 처음 등록

신규 서버의 `chaconne` 계정에서 다음 한 줄을 실행합니다.

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh --new abc-project
```

이 명령은 다음 작업을 완료합니다.

1. 공용 스킬과 전역 지침 설치
2. 중앙 GBrain에 `abc-project` 전용 공간과 접근 정책 생성
3. `abc-project` GBrain 카드 생성·연결
4. 중앙 GBrain SSH 프록시 연결
5. 카드와 정책 연결 검증

실제 생성 전에 내용을 확인하려면 clone 후 dry-run을 사용합니다.

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
~/kmh-agent-kit/install.sh --new abc-project --dry-run
~/kmh-agent-kit/install.sh --new abc-project
```

신규 서버는 다음 접속 조건을 갖춰야 합니다.

- GitHub에서 이 저장소를 clone할 수 있어야 합니다.
- `chaconne@49.247.45.243`에 비밀번호 없이 SSH 접속할 수 있어야 합니다.

최초 설치 직후 현재 셸에서도 일상 명령을 사용하려면 한 번 실행합니다.

```bash
source ~/.bashrc
```

### 이미 등록된 역할을 설치

저장소가 이미 있으면 해당 행의 명령 하나만 실행합니다.

| 역할 | 등록 이름 | 설치 명령 |
|---|---|---|
| 중앙 DB·GBrain `49.247.45.243` | `main` | `~/kmh-agent-kit/install.sh main` |
| FundKeeper `49.247.38.186` | `fundkeeper` | `~/kmh-agent-kit/install.sh fundkeeper` |
| Judy WSL | `judy` | `~/kmh-agent-kit/install.sh judy` |

저장소도 없는 장비에서는 역할에 맞는 한 줄을 그대로 실행합니다.

| 역할 | 최초 설치 명령 |
|---|---|
| 중앙 DB·GBrain | `git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh main` |
| FundKeeper | `git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh fundkeeper` |
| Judy WSL | `git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh judy` |

RNDLOG와 CEO Loan은 운영 서버 설치 대상이 아닙니다. 두 프로젝트의 지침·스킬·GBrain은 중앙
조정실에만 두고, 중앙 에이전트가 SSH로 운영 저장소를 관리합니다.

## 그 외

### 가능한 명령

| 명령 | 용도 |
|---|---|
| `kitpull` | 저장소를 받은 뒤 이 서버의 공용 자산과 매칭 도메인 재설치 |
| `kitpush` | 이 서버의 공용·매칭 도메인 변경 검증, 커밋, push |
| `./install.sh main` | 중앙 DB·GBrain 역할 설치 |
| `./install.sh fundkeeper` | FundKeeper 역할 설치 |
| `./install.sh judy` | Judy WSL 역할 설치 |
| `./install.sh --new abc-project` | 신규 등록 이름의 공간·정책·카드 생성 후 설치 |
| `./install.sh --new abc-project --dry-run` | 신규 생성 내용을 변경 없이 미리 확인 |
| `./install.sh` | GBrain 카드 없이 공용 스킬·전역 지침만 설치 |
| `./install.sh --project ~/exdigm exdigm` | 프로젝트 프로필만 별도로 연결 |
| `./install.sh --project ~/projects/rndlog rndlog` | 중앙 RNDLOG 조정실 연결 |
| `./install.sh --project ~/projects/ceoloan ceoloan` | 중앙 CEO Loan 조정실 연결 |
| `./install.sh --help` | 설치 명령 표시 |

이전 `--gbrain` 형식은 기존 자동화의 호환을 위해서만 유지합니다. 새 설치에는 위 표의 공식 명령을 사용합니다.

### 서버 자동 인식

최초 `./install.sh <등록 이름>`이 등록 이름을 해당 저장소의 Git 로컬 설정에 저장합니다. 이 값은 커밋되지 않으므로 서버마다 독립적으로 유지됩니다.

기존 설치는 첫 `kitpull` 또는 `kitpush`에서 현재 GBrain 카드를 읽어 등록 이름을 한 번 복구합니다. 이후에는 저장된 이름이 기준입니다.

- `kitpull`: Git 저장소 전체를 받은 뒤 공용 자산과 현재 등록 이름에 매칭되는 프로젝트 프로필만 실제 환경에 연결합니다.
- `kitpush`: 공용 파일, 현재 등록 이름의 카드, 매칭 도메인만 커밋·push합니다.
- 다른 도메인의 변경이 함께 있으면 `kitpush`는 변경 경로를 표시하고 중단합니다.
- 원격 변경이 먼저 있으면 `kitpush`는 커밋 전에 중단하고 `kitpull`을 안내합니다.

### 신규 등록 작동 원리

`./install.sh --new abc-project`는 다음 순서로 실행됩니다.

1. `gbrain-cards/abc-project.md` 범용 카드 생성
2. 중앙 GBrain에 `abc-project` 소스 생성
3. 중앙 기본 소스를 `default`로 복구하고 공용 조회 검증
4. `agents/abc-project/private` 읽기·쓰기 정책 등록
5. 현재 서버에 공용 자산·카드·`gbrain-abc-project` 프록시 설치
6. 실제 정책 조회로 연결 검증

같은 등록 이름의 기존 공간·정책·카드는 덮어쓰지 않습니다. 기존 정책이 예상한 접근 범위와 다르면 자동 수정하지 않고 중단합니다.

생성된 카드는 저장소의 신규 파일로 남습니다. 다른 서버도 같은 카드를 받게 하려면 내용을 검토한 뒤 커밋·push합니다.

### 서버별 자동 프로젝트 연결

| 등록 이름 | 자동 연결되는 프로젝트 프로필 |
|---|---|
| `main` | `~/exdigm`의 `exdigm` 프로필 |
| `fundkeeper` | `~/fundkeeper`의 `fundkeeper` 프로필 |
| 그 외 | 같은 이름의 프로젝트 폴더와 프로필이 모두 있을 때 연결 |

RNDLOG와 CEO Loan 프로젝트 프로필은 중앙 조정실에만 연결합니다. 운영 서버에는 프로젝트
프로필·공용 지침·GBrain 카드를 설치하지 않습니다.

### 설치 파일 연결 방식

| 설치 대상 | 저장소 원본 | 실제 사용 위치 |
|---|---|---|
| 공용 스킬 | `skills/common/` | `~/.claude/skills/`, `~/.agents/skills/` |
| 전역 지침 | `claude/CLAUDE.md`, `codex/AGENTS.md` | 각 도구의 전역 지침 위치 |
| 프로젝트 스킬 | `projects/` | 프로젝트의 `.claude/skills/`, `.agents/skills/` |
| GBrain 카드 | `gbrain-cards/` | `~/.gbrain-agent.md` |
| 원격 GBrain 프록시 | `gbrain/bin/gbrain-remote-proxy` | `~/.local/bin/gbrain-abc-project` 같은 이름 |

Linux에서는 저장소 원본을 실제 사용 위치에 심볼릭 링크합니다. 링크가 아닌 기존 파일은 삭제하지 않고 `~/.kmh-agent-kit-backup-날짜-시각/`에 보존합니다.

### 업데이트

모든 Linux·WSL 서버에서 같은 명령을 사용합니다.

```bash
kitpull
```

수정한 공용·도메인 자산을 올릴 때도 서버 이름 없이 실행합니다. 커밋 메시지는 생략할 수 있습니다.

```bash
kitpush
kitpush "설명할 커밋 메시지"
```

### 설치 확인

공통 확인:

```bash
python3 ~/kmh-agent-kit/scripts/check-skill-deps.py
readlink -f ~/.gbrain-agent.md
```

신규 `abc-project` 정책 확인:

```bash
gbrain-abc-project policy
```

중앙 GBrain 확인:

```bash
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
```

### Windows

Windows는 기존 PowerShell 설치기를 사용합니다.

| 역할 | 설치 명령 |
|---|---|
| Gram17 | `.\install.ps1 -Gbrain gram17` |
| Venture | `.\install.ps1 -Gbrain venture` |

먼저 저장소를 `$env:USERPROFILE\kmh-agent-kit`에 clone하고 그 폴더에서 명령을 실행합니다. Windows는 junction과 하드링크를 사용하며 Linux용 GBrain SSH 프록시와 systemd 서비스를 설치하지 않습니다.

Exdigm 운영 서버 `115.68.224.161`은 현재 이 저장소의 설치 대상이 아닙니다. 해당 서버에서는 위 설치 명령을 실행하지 않습니다.

### 저장소에 포함하는 범위

| 포함 | 포함하지 않음 |
|---|---|
| 공용 스킬과 전역 지침 | API 키·비밀번호·OAuth 토큰 |
| 프로젝트 프로필 | GBrain 데이터베이스와 백업 덤프 |
| GBrain 카드와 실행 래퍼 | Exdigm·Rndlog·Ceoloan 실제 서비스 코드 |
| 구조 검사와 설치 문서 | 한 서버에서만 쓰는 로컬 전용 자산 |

상세한 신규 서버 점검은 [New Server Onboarding](docs/onboarding-new-server.md), 스킬 관리 방법은 [Skill Management](docs/skill-management.md), 장애 해결은 [Troubleshooting](docs/troubleshooting.md)을 봅니다.
