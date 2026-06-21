# Sync And Release

이 저장소는 여러 서버의 에이전트 운영 설정을 같은 상태로 맞추기 위한 단일 소스입니다.

## Commit Scope

커밋 대상:

- `codex/AGENTS.md`
- `codex/skills/`
- `gbrain/bin/`
- `gbrain/systemd/`
- `docs/`
- `manifests/`
- `scripts/`

커밋 금지:

- `.env`
- API key, token, DB password
- GBrain DB dump
- 타사 스킬 원본
- Exdigm 애플리케이션 코드

## Update Flow

```bash
cd ~/kmh-agent-kit
git pull --ff-only
./install.sh
python3 scripts/check-skill-deps.py
```

스킬이나 GBrain 운영 파일을 수정한 뒤에는 focused check와 code-review-loop를 실행하고 커밋합니다.
