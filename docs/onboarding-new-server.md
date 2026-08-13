# New Server Onboarding

## 개요

새 Linux 서버의 공식 설치 경로는 `install.sh` 한 번입니다. 서버 이름을 주면 공용 자산, GBrain 카드, SSH 프록시, 알려진 프로젝트 프로필, 연결 검증까지 이어서 실행합니다.

```bash
~/kmh-agent-kit/install.sh rndlog
```

신규 에이전트는 `--new`로 중앙 GBrain 공간과 정책, 카드까지 함께 만듭니다.

```bash
~/kmh-agent-kit/install.sh --new analytics
```

## 퀵 설치 방법

### 중앙 DB·GBrain `49.247.45.243`

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh main
```

### FundKeeper `49.247.38.186`

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh fundkeeper
```

### Rndlog `49.247.207.147`

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh rndlog
```

### Ceoloan `49.247.205.170`

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh ceoloan
```

### Judy WSL

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && ~/kmh-agent-kit/install.sh judy
```

### 신규 에이전트

`analytics`라는 이름으로 먼저 확인:

```bash
~/kmh-agent-kit/install.sh --new analytics --dry-run
```

확인 후 생성·설치:

```bash
~/kmh-agent-kit/install.sh --new analytics
```

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

`--new analytics`는 다음 항목만 새로 만듭니다.

- 중앙 GBrain 소스 `analytics`
- 중앙 정책의 `[sources.analytics]`, `[agents.analytics]`
- 전용 쓰기 경로 `agents/analytics/private`
- 저장소 카드 `gbrain-cards/analytics.md`
- 현재 서버의 `~/.gbrain-agent.md`, `~/.local/bin/gbrain-analytics`

기존 공간·정책·카드는 덮어쓰지 않습니다. 정책 충돌이 있으면 중단합니다. 정책 변경 전 백업은 `agent-policy.toml.backup-날짜-시각`으로 남깁니다.

### 중앙 GBrain 보호 검증

새 공간을 추가한 뒤 설치기가 자동으로 확인합니다.

- 중앙 기본 소스: `default`
- 해석 단계: `brain_default`
- 공용 운영 프로토콜 조회
- 새 에이전트 정책 조회

이 검증 중 하나라도 실패하면 설치 성공으로 보고하지 않습니다.

### 기존 서버 업데이트

서버 이름까지 포함해 다시 실행합니다.

```bash
git -C ~/kmh-agent-kit pull --ff-only && ~/kmh-agent-kit/install.sh rndlog
```

### 설치 결과 확인

```bash
python3 ~/kmh-agent-kit/scripts/check-skill-deps.py
readlink -f ~/.gbrain-agent.md
```

Rndlog:

```bash
gbrain-rndlog policy
gbrain-rndlog get agents/rndlog/private/project-overview
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

- 기존 서버에는 `--new`를 쓰지 않고 `./install.sh rndlog`처럼 이름만 사용합니다.
- 신규 카드 파일은 자동 commit·push하지 않습니다. 내용을 검토한 뒤 저장소에 반영합니다.
- Exdigm 운영 서버 `115.68.224.161`은 현재 이 저장소의 설치 대상이 아닙니다.
- API 키, DB 비밀번호, OAuth 토큰은 저장소와 GBrain 카드에 넣지 않습니다.
