# KMH Agent Kit

KMH Agent Kit은 여러 서버의 Codex·Claude Code가 같은 스킬과 작업 규칙을 쓰게 만드는 저장소입니다. GBrain을 쓰는 서버에는 그 서버 역할에 맞는 카드도 연결합니다.

처음 설치할 때는 아래에서 **서버 이름을 찾고 명령을 그대로 실행**하면 됩니다. 에이전트명이나 프로젝트명을 직접 바꿔 넣는 예시는 사용하지 않습니다.

## 서버별 처음 설치

### 중앙 DB·GBrain 서버 — coconut-db (`49.247.45.243`)

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
cd ~/kmh-agent-kit
./install.sh
./install.sh --gbrain main
./install.sh --project ~/exdigm exdigm
```

### FundKeeper 서버 — coconut-main (`49.247.38.186`)

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
cd ~/kmh-agent-kit
./install.sh
./install.sh --gbrain fundkeeper
./install.sh --project ~/fundkeeper fundkeeper
```

### Rndlog 서버 (`49.247.207.147`)

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
cd ~/kmh-agent-kit
./install.sh
./install.sh --gbrain rndlog
```

### Ceoloan 서버 (`49.247.205.170`)

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
cd ~/kmh-agent-kit
./install.sh
./install.sh --gbrain ceoloan
```

### Judy WSL

```bash
git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit
cd ~/kmh-agent-kit
./install.sh
./install.sh --gbrain judy
```

### Gram17 Windows PC

```powershell
git clone https://github.com/chaconne67/kmh-agent-kit.git $env:USERPROFILE\kmh-agent-kit
cd $env:USERPROFILE\kmh-agent-kit
.\install.ps1
.\install.ps1 -Gbrain gram17
```

### Venture Windows PC

```powershell
git clone https://github.com/chaconne67/kmh-agent-kit.git $env:USERPROFILE\kmh-agent-kit
cd $env:USERPROFILE\kmh-agent-kit
.\install.ps1
.\install.ps1 -Gbrain venture
```

Exdigm 운영 서버(`115.68.224.161`)는 현재 이 저장소로 관리하지 않습니다. 그 서버에서는 위 명령을 임의로 실행하지 않습니다.

## 설치 명령 표

### Linux·WSL

| 목적 | 실행할 명령 |
|---|---|
| 가능한 명령 보기 | `./install.sh --help` |
| 공용 스킬·전역 지침 설치 | `./install.sh` |
| 중앙 GBrain 서버 카드 | `./install.sh --gbrain main` |
| FundKeeper 카드 | `./install.sh --gbrain fundkeeper` |
| Rndlog 카드 | `./install.sh --gbrain rndlog` |
| Ceoloan 카드 | `./install.sh --gbrain ceoloan` |
| Judy 카드 | `./install.sh --gbrain judy` |
| Venture 카드 | `./install.sh --gbrain venture` |
| Gram17 카드 | `./install.sh --gbrain gram17` |
| Hermes Sam 카드 | `./install.sh --gbrain sam` |
| Exdigm 프로젝트 스킬 | `./install.sh --project ~/exdigm exdigm` |
| FundKeeper 프로젝트 스킬 | `./install.sh --project ~/fundkeeper fundkeeper` |
| Testbed 프로젝트 스킬 | `./install.sh --project ~/testbed testbed` |

한 계정의 `~/.gbrain-agent.md`에는 카드 하나만 연결됩니다. 다른 카드 명령을 실행하면 기존 카드가 새 카드로 바뀝니다. `sam`은 Hermes Sam 전용 환경에서만 사용합니다.

### Windows PowerShell

| 목적 | 실행할 명령 |
|---|---|
| 공용 스킬·전역 지침 설치 | `.\install.ps1` |
| Gram17 카드 | `.\install.ps1 -Gbrain gram17` |
| Venture 카드 | `.\install.ps1 -Gbrain venture` |
| Exdigm 프로젝트 스킬 | `.\install.ps1 -Project $env:USERPROFILE\exdigm -ProfileName exdigm` |
| FundKeeper 프로젝트 스킬 | `.\install.ps1 -Project $env:USERPROFILE\fundkeeper -ProfileName fundkeeper` |
| Testbed 프로젝트 스킬 | `.\install.ps1 -Project $env:USERPROFILE\testbed -ProfileName testbed` |

Windows 설치기는 관리자 권한 없이 junction과 하드링크를 사용합니다. GBrain의 Linux 실행 프록시는 설치하지 않으므로 카드에 적힌 SSH 명령으로 중앙 서버를 호출합니다.

## 무엇이 어떻게 연결되는가

| 설치 대상 | 원본 | 실제 사용 위치 | 결과 |
|---|---|---|---|
| 공용 스킬 | `skills/common/` | `~/.claude/skills/`, `~/.codex/skills/` | 두 도구가 같은 스킬을 사용 |
| 전역 지침 | `claude/CLAUDE.md`, `codex/AGENTS.md` | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` | 서버마다 같은 기본 작업 규칙 사용 |
| 프로젝트 스킬 | `projects/` | 각 프로젝트의 `.claude/skills/`, `.codex/skills/` | 해당 프로젝트에서만 도메인 스킬 노출 |
| GBrain 카드 | `gbrain-cards/` | `~/.gbrain-agent.md` | 에이전트가 사용할 기억 공간과 규칙 선택 |
| GBrain 프록시 | `gbrain/bin/gbrain-remote-proxy` | `~/.local/bin/gbrain-rndlog` 등 | 원격 서버가 중앙 GBrain을 SSH로 호출 |

Linux에서는 위 위치를 저장소 원본에 **심볼릭 링크**합니다. 따라서 원본을 수정하면 즉시 실제 에이전트 환경에도 반영되고, 다른 서버는 `git pull`만 하면 같은 내용을 받습니다.

링크가 아닌 기존 파일이 있으면 지우지 않고 `~/.kmh-agent-kit-backup-날짜-시각/`으로 옮긴 뒤 연결합니다. 비밀번호·API 키·GBrain DB 데이터는 이 저장소에 포함하지 않습니다.

## 공용 스킬과 프로젝트 스킬

| 구분 | 원본 위치 | 연결 위치 | 예시 |
|---|---|---|---|
| 여러 프로젝트가 함께 쓰는 공용 스킬 | `skills/common/` | Claude·Codex 전역 | `problem-solving`, `code-review` |
| 특정 업무에서만 쓰는 프로젝트 스킬 | `skills/domains/` | 해당 프로젝트 프로필 | `data-extraction`, `fundkeeper-deploy` |

프로젝트 스킬을 전역에 연결하면 다른 프로젝트에서도 잘못 발동할 수 있습니다. `scripts/check-skill-deps.py`가 이 배치 오류를 검사합니다.

## 이 저장소에 넣지 않는 것

- API 키, 비밀번호, OAuth 토큰
- GBrain 데이터베이스와 백업 덤프
- 외부에서 받은 타사 스킬 원본
- Exdigm·Rndlog·Ceoloan 같은 실제 서비스 코드
- 한 서버·한 프로젝트에서만 사용하는 로컬 전용 자산

## 설치 후 확인

Linux 서버에서는 다음을 실행합니다.

```bash
cd ~/kmh-agent-kit
python3 scripts/check-skill-deps.py
readlink -f ~/.gbrain-agent.md
```

Rndlog 서버라면 중앙 GBrain 연결도 확인합니다.

```bash
gbrain-rndlog get agents/rndlog/private/project-overview
```

Ceoloan과 FundKeeper는 각각 `gbrain-ceoloan`, `gbrain-fundkeeper`로 같은 방식으로 확인합니다. 중앙 GBrain 서버는 다음 명령을 사용합니다.

```bash
~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast
```

## 업데이트 방법

기존 서버는 다시 clone하지 않습니다.

```bash
cd ~/kmh-agent-kit
git pull --ff-only
```

문서·기존 스킬·기존 지침 수정은 pull 즉시 반영됩니다. 새 스킬이 추가·삭제됐거나 `gbrain/` 실행 파일과 서비스가 바뀐 경우에는 전역 설치를 한 번 더 실행합니다.

```bash
./install.sh
```

Windows는 pull 후 전역 지침과 GBrain 카드의 하드링크를 다시 연결합니다.

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

## 자주 하는 작업

| 작업 | 명령 |
|---|---|
| 현재 변경 확인 | `git status --short` |
| 구조·의존성 검사 | `python3 scripts/check-skill-deps.py` |
| 공용 스킬을 Claude와 Codex에 연결 | `python3 scripts/link-skill.py add problem-solving --claude --codex` |
| Exdigm 스킬을 프로젝트 프로필에 연결 | `python3 scripts/link-skill.py add data-extraction --project exdigm` |
| 다른 서버의 변경 받기 | `git pull --ff-only` |

스킬을 새로 만들거나 배치하는 방법은 [Skill Management](docs/skill-management.md), 새 서버의 세부 점검은 [New Server Onboarding](docs/onboarding-new-server.md), 장애 해결은 [Troubleshooting](docs/troubleshooting.md)을 봅니다.

## 관리 원칙

- 기존 GBrain 기능·스킬·프로젝트 코드를 먼저 찾아 재사용합니다.
- 새 코드는 기존 기능으로 해결할 수 없을 때만 추가합니다.
- 임시 우회보다 원인을 고칩니다.
- 실행 동작이 달라지는 변경은 검증하고 코드 리뷰를 거칩니다.

## 저장소 구조

```text
skills/common/                 여러 프로젝트가 함께 쓰는 공용 스킬 원본
skills/domains/                특정 도메인에서만 쓰는 스킬 원본
claude/                        Claude Code 전역 프로필과 지침
codex/                         Codex 전역 프로필과 지침
projects/                      프로젝트별 스킬 프로필
gbrain-cards/                  에이전트별 GBrain 카드
gbrain/                        GBrain 실행 래퍼와 Linux 서비스 파일
scripts/                       구조 검사와 스킬 연결 도구
docs/                          상세 운영 문서
```
