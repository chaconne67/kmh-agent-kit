# New Server Onboarding

새 서버에서는 **공용 설치 → 서버 카드 설치 → 필요한 프로젝트 프로필 설치 → 검증** 순서로 진행합니다. 중앙 GBrain 서버와 일반 애플리케이션 서버의 설정은 다르므로 섞지 않습니다.

## 1. 기존 파일 확인

설치기는 기존 일반 파일을 백업하지만, 먼저 현재 상태를 확인합니다. 비밀값은 출력하지 않습니다.

```bash
ls -ld ~/.claude ~/.codex ~/.gbrain ~/kmh-agent-kit 2>/dev/null || true
```

## 2. 저장소 설치

Linux와 WSL에서 공통으로 실행합니다.

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
cd ~/kmh-agent-kit
./install.sh
```

기존 파일은 `~/.kmh-agent-kit-backup-날짜-시각/`에 보존됩니다. 공용 스킬과 지침은 저장소에 심볼릭 링크되므로 이후에는 `git pull`로 갱신됩니다.

## 3. 이 서버에 맞는 명령 실행

아래 표에서 현재 서버 한 줄만 실행합니다.

| 서버 | 실행할 명령 |
|---|---|
| 중앙 DB·GBrain `49.247.45.243` | `./install.sh --gbrain main` |
| FundKeeper `49.247.38.186` | `./install.sh --gbrain fundkeeper` |
| Rndlog `49.247.207.147` | `./install.sh --gbrain rndlog` |
| Ceoloan `49.247.205.170` | `./install.sh --gbrain ceoloan` |
| Judy WSL | `./install.sh --gbrain judy` |

프로젝트 프로필이 있는 서버만 이어서 실행합니다.

| 서버·프로젝트 | 실행할 명령 |
|---|---|
| 중앙 서버의 Exdigm | `./install.sh --project ~/exdigm exdigm` |
| FundKeeper 서버 | `./install.sh --project ~/fundkeeper fundkeeper` |
| Testbed가 `~/testbed`에 있는 서버 | `./install.sh --project ~/testbed testbed` |

Rndlog와 Ceoloan에는 현재 별도 프로젝트 프로필이 없으므로 GBrain 카드까지만 설치합니다.

## 4. 일반 서버의 GBrain 연결 확인

Rndlog:

```bash
readlink -f ~/.gbrain-agent.md
readlink -f ~/.local/bin/gbrain-rndlog
gbrain-rndlog get agents/rndlog/private/project-overview
```

Ceoloan:

```bash
readlink -f ~/.gbrain-agent.md
readlink -f ~/.local/bin/gbrain-ceoloan
gbrain-ceoloan query "ceoloan 운영 구조"
```

FundKeeper:

```bash
readlink -f ~/.gbrain-agent.md
readlink -f ~/.local/bin/gbrain-fundkeeper
gbrain-fundkeeper query "fundkeeper 운영 구조"
```

이 서버들은 SSH 프록시로 중앙 GBrain(`49.247.45.243`)을 사용합니다. 로컬 GBrain DB나 `gbrain-http.service`를 새로 만들지 않습니다.

## 5. 중앙 GBrain 서버만 추가 설정

이 단계는 `49.247.45.243`에서만 실행합니다. 일반 애플리케이션 서버에서는 건너뜁니다.

GBrain CLI가 없을 때만 Bun을 설치합니다.

```bash
command -v unzip || { sudo apt-get update && sudo apt-get install -y unzip; }
command -v bun || curl -fsSL https://bun.sh/install | bash
```

기존 PostgreSQL·pgvector와 GBrain 설정을 먼저 확인합니다. 새 DB를 임의로 만들지 않습니다.

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
~/.gbrain/bin/gbrain_with_google_env.sh stats
~/.gbrain/bin/gbrain_with_google_env.sh sources default default
```

서비스를 활성화합니다.

```bash
systemctl --user daemon-reload
systemctl --user enable --now gbrain-http.service
systemctl --user enable --now gbrain-memory-distill.timer
systemctl --user status gbrain-http.service --no-pager
systemctl --user list-timers gbrain-memory-distill.timer --no-pager
```

## 6. 전체 설치 검증

```bash
cd ~/kmh-agent-kit
python3 scripts/check-skill-deps.py
./install.sh --help
git status --short
```

정상 결과:

- 스킬 구조 검사가 `통과`로 끝납니다.
- 도움말에 전역·GBrain·프로젝트 설치 명령이 표시됩니다.
- 설치만 했다면 저장소 작업트리는 깨끗합니다.
- `~/.gbrain-agent.md`가 현재 서버에 맞는 카드 원본을 가리킵니다.

## Windows 설치

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

Windows는 junction과 하드링크를 사용하므로 관리자 권한이나 개발자 모드가 필요 없습니다. Linux 전용 GBrain 프록시와 systemd 서비스는 설치하지 않습니다.

## 기존 서버 업데이트

```bash
cd ~/kmh-agent-kit
git pull --ff-only
```

새 스킬 추가·삭제 또는 `gbrain/` 실행 파일·서비스 변경이 포함된 업데이트만 다음 명령을 한 번 더 실행합니다.

```bash
./install.sh
```

Windows는 pull 뒤에 해당 기기의 두 설치 명령을 다시 실행합니다.

Gram17:

```powershell
cd $env:USERPROFILE\kmh-agent-kit
git pull --ff-only
.\install.ps1
.\install.ps1 -Gbrain gram17
```

Venture:

```powershell
cd $env:USERPROFILE\kmh-agent-kit
git pull --ff-only
.\install.ps1
.\install.ps1 -Gbrain venture
```

## 주의

- `./install.sh --rndlog`는 유효한 명령이 아닙니다. `./install.sh --gbrain rndlog`를 사용합니다.
- 한 계정에는 GBrain 카드 하나만 연결합니다.
- Exdigm 운영 서버(`115.68.224.161`)는 현재 이 저장소의 설치 대상이 아닙니다.
- API 키, DB 비밀번호, OAuth 토큰은 이 저장소에 넣지 않습니다.
