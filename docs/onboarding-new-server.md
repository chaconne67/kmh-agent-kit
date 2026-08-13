# New Server Onboarding

## 개요

설치 명령에 넣는 값은 장비의 호스트명이 아니라 GBrain 공간·정책·카드를 고르는 **등록 이름**입니다.

| 상황 | 설치 방식 |
|---|---|
| 새로운 프로젝트 역할을 처음 등록 | `--new` 사용 |
| 기존 역할을 새 장비에 설치 | 기존 등록 이름 사용 |

GBrain 등록 이름은 영문 소문자·숫자·중간 하이픈으로 된 1~32자입니다. 밑줄은 허용되지 않으므로 `abc_project`는 `abc-project`로 등록합니다.

최초 설치 뒤에는 모든 서버에서 `kitpull`, `kitpush`만 사용합니다. 최초 설치가 저장한 등록 이름으로 공용 자산과 매칭 도메인을 자동 선택합니다.

## 퀵 설치 방법

### 처음 등록하는 `abc_project` 서버

먼저 변경 내용을 확인하려면:

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh --new abc-project --dry-run
```

확인 후 실제 설치:

```bash
~/kmh-agent-kit/install.sh --new abc-project
```

처음부터 바로 설치하려면 다음 한 줄만 실행합니다.

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh --new abc-project
```

새 셸을 열거나 `source ~/.bashrc`를 실행하면 `kitpull`, `kitpush`를 사용할 수 있습니다.

### 기존 역할을 새 장비에 설치

| 역할 | 최초 설치 명령 |
|---|---|
| 중앙 DB·GBrain `49.247.45.243` | `git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh main` |
| FundKeeper `49.247.38.186` | `git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh fundkeeper` |
| Rndlog `49.247.207.147` | `git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh rndlog` |
| Ceoloan `49.247.205.170` | `git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh ceoloan` |
| Judy WSL | `git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh judy` |

## 그 외

### 설치 전 조건

- 실행 계정은 `chaconne`을 기준으로 합니다.
- 원격 서버는 `chaconne@49.247.45.243`로 비밀번호 없이 SSH 접속할 수 있어야 합니다.
- GitHub 저장소를 clone할 SSH 키가 준비되어 있어야 합니다.
- 기존 `~/.claude`, `~/.codex`, `~/.gbrain` 일반 파일은 설치기가 백업합니다.

현재 상태 확인:

```bash
ls -ld ~/.claude ~/.codex ~/.gbrain ~/kmh-agent-kit 2>/dev/null || true
ssh -o BatchMode=yes -o ConnectTimeout=10 chaconne@49.247.45.243 true
```

### 신규 생성 범위

`--new abc-project`는 다음 항목만 새로 만듭니다.

- 중앙 GBrain 소스 `abc-project`
- 중앙 정책의 `[sources.abc-project]`, `[agents.abc-project]`
- 전용 쓰기 경로 `agents/abc-project/private`
- 저장소 카드 `gbrain-cards/abc-project.md`
- 현재 서버의 `~/.gbrain-agent.md`, `~/.local/bin/gbrain-abc-project`

기존 공간·정책·카드는 덮어쓰지 않습니다. 정책 충돌이 있으면 중단합니다. 정책 변경 전 백업은 `agent-policy.toml.backup-날짜-시각`으로 남깁니다.

### 중앙 GBrain 보호 검증

새 공간을 추가한 뒤 설치기가 자동으로 확인합니다.

- 중앙 기본 소스: `default`
- 해석 단계: `brain_default`
- 공용 운영 프로토콜 조회
- 새 에이전트 정책 조회

이 검증 중 하나라도 실패하면 설치 성공으로 보고하지 않습니다.

### 기존 서버 업데이트

모든 Linux·WSL 서버에서 같은 명령을 실행합니다.

```bash
kitpull
```

공용 또는 현재 서버의 매칭 도메인 변경을 올릴 때:

```bash
kitpush
```

최초 설치가 등록 이름을 Git 로컬 설정에 저장하므로 이름을 다시 입력하지 않습니다. 다른 도메인의 변경이 있으면 `kitpush`가 해당 경로를 표시하고 중단합니다. 원격 변경이 먼저 있어도 커밋 전에 중단하고 `kitpull`을 안내합니다.

### 설치 결과 확인

```bash
python3 ~/kmh-agent-kit/scripts/check-skill-deps.py
readlink -f ~/.gbrain-agent.md
```

신규 `abc-project`:

```bash
gbrain-abc-project policy
```

Ceoloan:

```bash
gbrain-ceoloan policy
```

FundKeeper:

```bash
gbrain-fundkeeper policy
```

### 중앙 GBrain 서버만 확인할 항목

일반 애플리케이션 서버에서는 로컬 GBrain DB나 `gbrain-http.service`를 만들지 않습니다. 아래 명령은 `49.247.45.243`에서만 실행합니다.

```bash
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
~/.gbrain/bin/gbrain_with_google_env.sh sources current
systemctl --user status gbrain-http.service --no-pager
```

### Windows

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

Windows는 junction과 하드링크를 사용하며 Linux 전용 GBrain 프록시·systemd 서비스는 설치하지 않습니다.

### 주의

- 기존 역할을 새 장비에 설치할 때는 `--new`를 쓰지 않고 위 표의 등록 이름을 사용합니다.
- 신규 카드 파일은 자동 commit·push하지 않습니다. 내용을 검토한 뒤 저장소에 반영합니다.
- Exdigm 운영 서버 `115.68.224.161`은 현재 이 저장소의 설치 대상이 아닙니다.
- API 키, DB 비밀번호, OAuth 토큰은 저장소와 GBrain 카드에 넣지 않습니다.
