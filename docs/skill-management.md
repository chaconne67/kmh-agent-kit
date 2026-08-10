# Skill Management

이 저장소의 `skills/`가 모든 커스텀 스킬의 단일 원본이다. live 위치(`~/.claude/skills`, `~/.codex/skills`, `<프로젝트>/.claude/skills`, `<프로젝트>/.codex/skills`)에는 프로필 심링크만 있다. 외부에서 가져온 스킬 원본은 포함하지 않는다.

## 공용 / 도메인 구분

**분류는 원본 위치가, 발동 범위는 프로필이 정한다.** 두 축을 분리해 두면 "무엇인지"와 "어디서 뜨는지"를 따로 바꿀 수 있다.

| | 원본 | 전역 프로필 | 프로젝트 프로필 |
|---|---|---|---|
| 공용 스킬 | `skills/common/<이름>` | O (어디서든 발동) | 보통 불필요 |
| 도메인 스킬 | `skills/domains/<도메인>/<이름>` | **금지** | O (그 프로젝트에서만 발동) |

판정 기준은 "이 스킬이 특정 제품·업무 맥락을 알아야만 쓸모가 있는가"다. 그렇다면 도메인 스킬이다. 현재 도메인은 `fundkeeper`, `testbed` 두 개다.

`scripts/check-skill-deps.py`가 도메인 스킬의 전역 배치를 오류로 막고, `scripts/link-skill.py`도 같은 규칙을 적용해 잘못된 배치를 애초에 만들지 않는다.

도메인 스킬은 프로필을 연결한 폴더에서만 뜬다. 그 도메인 작업을 하는 폴더에 반드시 연결해야 한다 — 연결을 잊으면 스킬이 조용히 안 뜨는 것이 이 구조의 유일한 함정이다.

## 배치 규칙

- **배치의 정본은 프로필 심링크다.** 어떤 스킬이 어느 도구·프로젝트에서 발동하는지는 `claude/skills/`, `codex/skills/`, `projects/<프로젝트>/skills/`의 링크 존재 여부가 결정한다.
- `manifests/skills.json`은 심링크로 표현할 수 없는 **스킬 간 의존관계만** 담는다. 배치 정보를 여기 중복 기록하지 않는다.
- **키트 소유 기준은 "여러 기기·프로젝트가 공유하는가"다.** 한 서버·한 프로젝트에서만 쓰는 스킬·지침·문서는 키트에 넣지 않고 그 프로젝트 폴더 안에 로컬 실파일로 두며, 프로젝트 레포가 gitignore한다. 여러 기기에서 쓰는 도메인 스킬은 키트가 소유하되 `skills/domains/` 아래에 둔다.
  - 예: exdigm의 스킬 4개(auto-posting, extraction-pipeline-verify, exdigm-design, exdigm-hermes-agent)와 지식 문서는 `~/exdigm/.claude/skills/`·`~/exdigm/.claude/agent-docs/`에 있다. `.codex/skills/`는 `.claude/skills/`를 가리키는 로컬 심링크로 두 도구가 같은 원본을 쓴다.
  - 예: exdigm-deploy 스킬은 해당 서버의 `~/.codex/skills/`에 실폴더로만 있다.

## 일상 수정 (git만 사용)

한 서버에서 스킬·지침을 수정하면 심링크 덕에 레포 작업트리가 이미 바뀌어 있다:

```bash
cd ~/kmh-agent-kit
git status --short          # 수정 내용 확인
git add -A && git commit -m "..." && git push
```

다른 서버:

```bash
cd ~/kmh-agent-kit && git pull --ff-only
```

pull만으로 live에 즉시 반영된다(같은 파일이므로). `install.sh` 재실행은 **새 스킬이 추가·삭제된 경우에만** 필요하다(새 링크 생성/깨진 링크 정리).

## 새 스킬 추가

1. 공용이면 `skills/common/<이름>/SKILL.md`, 도메인 전용이면 `skills/domains/<도메인>/<이름>/SKILL.md` 작성 (frontmatter: `name`, `description` — description이 발동 조건의 정본).
2. 발동시킬 프로필에 링크 추가. `scripts/link-skill.py`가 원본 위치를 찾아 상대경로를 계산하고, 작업트리 표현과 무관하게 git 인덱스에 항상 심링크(mode 120000)로 등록한다:
   ```bash
   python scripts/link-skill.py add <이름> --claude --codex     # 공용
   python scripts/link-skill.py add <이름> --project <도메인>    # 도메인
   ```
   손으로 걸 때는(Linux 한정) 상대 심링크여야 한다:
   ```bash
   ln -s ../../skills/common/<이름> claude/skills/<이름>
   ln -s ../../../skills/domains/<도메인>/<이름> projects/<도메인>/skills/<이름>
   ```
3. 다른 스킬을 전제로 하면 `manifests/skills.json`의 `depends_on`에 추가.
4. `python3 scripts/check-skill-deps.py` 통과 확인 → 커밋·푸시.
5. 다른 서버: `git pull && ./install.sh`.

작성 원칙은 `skills/common/skill-writing-guide/`와 `skills/common/prompt-guide/`를 따른다.

## 프로젝트 온보딩 (의존성 기반 선별 설치)

새 프로젝트에 키트를 적용할 때 에이전트가 수행하는 절차:

1. **필요 스킬 파악**: 프로젝트의 성격(도메인, 사용하는 도구, 반복 작업)을 분석해 필요한 스킬을 고른다. 그 프로젝트의 도메인 스킬(`skills/domains/<도메인>/`)은 전부, 공용 스킬은 전역에 없는 것만 고르면 된다. 각 SKILL.md의 description이 판단 기준이다.
2. **의존성 폐포 계산**: 고른 스킬마다 `manifests/skills.json`의 `depends_on`을 재귀로 따라가 필요한 스킬을 전부 포함시킨다. 의존 스킬이 이미 전역 프로필(claude/skills, codex/skills)에 있으면 프로젝트 프로필에 중복으로 넣지 않아도 된다.
3. **프로필 생성·커밋**:
   ```bash
   python scripts/link-skill.py add <이름> --project <프로젝트>   # 선별된 스킬마다
   # 프로젝트 전용 지침이 있으면 projects/<프로젝트>/CLAUDE.md, AGENTS.md 작성
   python3 scripts/check-skill-deps.py
   git add -A && git commit -m "Add <프로젝트> project profile" && git push
   ```
4. **프로젝트에 연결**:
   ```bash
   ./install.sh --project <프로젝트 경로> <프로젝트명>
   ```

프로젝트 지침 파일 소유권 판정:

1. 프로젝트 내용이 그 프로젝트에서만 쓰이면 → 프로젝트 폴더의 로컬 파일이 정본, 키트에 넣지 않는다.
2. 여러 기기·프로젝트가 공유할 내용이면 → 키트 `projects/<프로젝트>/`에 두고 live는 심링크로 연결한다.

## Windows 기기

`install.ps1`을 쓴다. 개발자 모드도 관리자 권한도 필요 없고, 별도 폴백 절차도 없다.

```powershell
git clone https://github.com/chaconne67/kmh-agent-kit.git $env:USERPROFILE\kmh-agent-kit
cd $env:USERPROFILE\kmh-agent-kit
.\install.ps1
```

동작이 Linux와 다른 지점은 세 곳뿐이다:

- **live 연결** — 심링크 대신 junction(디렉토리)·하드링크(파일). 권한이 필요 없고, live에서 편집하면 레포 작업트리가 바뀌는 동작은 같다.
- **프로필 항목** — 개발자 모드가 꺼진 Windows는 git이 `core.symlinks=false`로 clone하므로 `claude/skills/<이름>`이 링크가 아니라 대상 경로만 담긴 일반 파일이 된다. `install.ps1`과 `check-skill-deps.py`가 이 표현도 링크로 인정한다.
- **GBrain 런타임** — bash 래퍼·systemd 유닛은 건너뛴다. 규칙 카드(`-Gbrain`)는 연결된다.

**주의**: 이 기기에서 프로필 링크를 손으로 만들면(탐색기 복사, `New-Item -ItemType File` 등) git에 일반 파일로 커밋되어 **Linux 서버의 설치가 조용히 깨진다**. 반드시 `scripts/link-skill.py`를 써서 인덱스에 심링크로 등록한다.

하드링크는 inode 공유라서, 일부 에디터처럼 저장 시 파일을 새로 만들어 교체하는 방식이면 연결이 끊긴다. `~/.claude/CLAUDE.md`를 편집한 뒤 레포 `git status`에 변경이 안 보이면 `.\install.ps1`을 다시 실행해 다시 잇는다.

## GBrain 에이전트 카드

GBrain 사용 규칙은 서버가 아니라 **에이전트 단위**로 다르다(같은 서버에 Codex·Hermes 프로필 등 여러 에이전트가 있을 수 있다). 그래서 공유 지침(CLAUDE.md·AGENTS.md)의 GBrain 섹션은 내용 대신 카드 참조만 갖는다:

- 카드 원본: `gbrain-cards/<에이전트>.md` (git 관리)
- 연결: `./install.sh --gbrain <에이전트>` → `~/.gbrain-agent.md` 심링크
- 카드가 없는 서버: 에이전트가 GBrain 규칙 전체를 건너뛴다 (임포트 실패해도 세션은 정상 — 2026-07-21 실측)

공간(사적 메모리) 구조 — GBrain 본체 서버(coconut-db) 기준:

- 등록부는 `~/.gbrain/memory/agent-policy.toml` 하나다. `[agents.<이름>]`의 `private_source`(필수)·`private_prefix`(선택)가 공간을 정의한다.
- 래퍼는 단일 스크립트 `gbrain-agent`(kit `gbrain/bin/`)뿐이다. `gbrain-<이름>` 심링크는 install.sh가 정책 파일에서 자동 생성하며, 호출된 이름으로 에이전트를 감지한다. 에이전트별 사본 스크립트를 만들지 않는다.
- 공용(default) 직접 쓰기는 없다. 공용 반영은 사적 공간 기록 후 주인님 승격 단일 경로다 (pending-shared 제안 흐름은 2026-07-21 폐지).

새 공간 에이전트 추가 절차:

1. 본체 서버 정책 파일에 `[sources.<이름>]`·`[agents.<이름>]` 추가 (`private_source` 필수). GBrain 소스 등록·설정 변경 후에는 반드시 bare CLI로 공용 페이지 1건을 `get`해 기본 소스 라우팅이 유지되는지 재검증한다 (incident/gbrain-cli-source-resolution 교훈).
2. `./install.sh` 재실행 → `gbrain-<이름>` 링크 자동 생성.
3. `gbrain-cards/<이름>.md` 카드 작성·커밋.
4. 에이전트가 있는 기기에서 `./install.sh --gbrain <이름>`. 본체가 아닌 기기에서는 이 명령이 카드 연결과 함께 SSH 프록시 링크(`~/.local/bin/gbrain-<이름>` → kit `gbrain/bin/gbrain-remote-proxy`)까지 만든다. 전제: 그 기기의 SSH 키가 본체 서버에 등록되어 있어야 한다.

## 검증

```bash
python3 ~/kmh-agent-kit/scripts/check-skill-deps.py
```

프로필 링크 해상, 고아 스킬, 의존성 누락, Codex system skill 부재를 검사한다.
