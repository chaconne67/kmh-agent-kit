# Skill Management

이 저장소의 `skills/`가 모든 커스텀 스킬의 단일 원본이다. live 위치(`~/.claude/skills`, `~/.codex/skills`, `<프로젝트>/.claude/skills`, `<프로젝트>/.codex/skills`)에는 프로필 심링크만 있다. 외부에서 가져온 스킬 원본은 포함하지 않는다.

## 배치 규칙

- **배치의 정본은 프로필 심링크다.** 어떤 스킬이 어느 도구·프로젝트에서 발동하는지는 `claude/skills/`, `codex/skills/`, `projects/<프로젝트>/skills/`의 링크 존재 여부가 결정한다.
- `manifests/skills.json`은 심링크로 표현할 수 없는 **스킬 간 의존관계만** 담는다. 배치 정보를 여기 중복 기록하지 않는다.
- 도메인 전용이라 공유하지 않는 스킬(예: exdigm-deploy)은 레포에 넣지 않고 해당 서버의 live 디렉토리에 실폴더로 둔다.

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

1. `skills/<이름>/SKILL.md` 작성 (frontmatter: `name`, `description` — description이 발동 조건의 정본).
2. 발동시킬 프로필에 상대 심링크 추가:
   ```bash
   ln -s ../../skills/<이름> claude/skills/<이름>     # Claude 전역
   ln -s ../../skills/<이름> codex/skills/<이름>      # Codex 전역
   ln -s ../../../skills/<이름> projects/<프로젝트>/skills/<이름>   # 프로젝트
   ```
3. 다른 스킬을 전제로 하면 `manifests/skills.json`의 `depends_on`에 추가.
4. `python3 scripts/check-skill-deps.py` 통과 확인 → 커밋·푸시.
5. 다른 서버: `git pull && ./install.sh`.

작성 원칙은 `skills/skill-writing-guide/`와 `skills/prompt-guide/`를 따른다.

## 프로젝트 온보딩 (의존성 기반 선별 설치)

새 프로젝트에 키트를 적용할 때 에이전트가 수행하는 절차:

1. **필요 스킬 파악**: 프로젝트의 성격(도메인, 사용하는 도구, 반복 작업)을 분석해 `skills/`에서 필요한 스킬을 고른다. 각 SKILL.md의 description이 판단 기준이다.
2. **의존성 폐포 계산**: 고른 스킬마다 `manifests/skills.json`의 `depends_on`을 재귀로 따라가 필요한 스킬을 전부 포함시킨다. 의존 스킬이 이미 전역 프로필(claude/skills, codex/skills)에 있으면 프로젝트 프로필에 중복으로 넣지 않아도 된다.
3. **프로필 생성·커밋**:
   ```bash
   mkdir -p projects/<프로젝트>/skills
   ln -s ../../../skills/<이름> projects/<프로젝트>/skills/<이름>   # 선별된 스킬마다
   # 프로젝트 전용 지침이 있으면 projects/<프로젝트>/CLAUDE.md, AGENTS.md 작성
   python3 scripts/check-skill-deps.py
   git add -A && git commit -m "Add <프로젝트> project profile" && git push
   ```
4. **프로젝트에 연결**:
   ```bash
   ./install.sh --project <프로젝트 경로> <프로젝트명>
   ```

프로젝트 지침 파일 소유권: 프로젝트 자체 git 레포가 CLAUDE.md·AGENTS.md를 이미 추적하면(예: gbrain) 그 레포가 정본이고 키트에 넣지 않는다. 프로젝트 레포가 이 파일들을 gitignore하면(예: exdigm) 키트의 `projects/<프로젝트>/`가 정본이고 live 파일은 심링크다.

## Windows 기기

git 심링크가 동작하려면 Windows에서 다음이 필요하다:

1. 설정 → 개발자 모드(Developer Mode) 활성화 (또는 관리자 권한).
2. `git config --global core.symlinks true` **후에** clone.

심링크를 쓸 수 없는 기기에서는 폴백으로:

- 스킬: live `skills/<이름>/SKILL.md`를 frontmatter(name, description)만 있는 실파일 래퍼로 만들고 본문에 `~/kmh-agent-kit/skills/<이름>/SKILL.md를 읽고 따르라` 한 줄을 둔다.
- CLAUDE.md: 실파일에 `@~/kmh-agent-kit/claude/CLAUDE.md` 임포트 한 줄만 둔다 (공식 지원).

폴백 기기에서는 스킬 description 변경 시 래퍼를 다시 만들어야 한다.

## 검증

```bash
python3 ~/kmh-agent-kit/scripts/check-skill-deps.py
```

프로필 링크 해상, 고아 스킬, 의존성 누락, Codex system skill 부재를 검사한다.
