# Skill Management

이 저장소는 사용자 커스텀 스킬과 wrapper 스킬을 관리합니다. 외부에서 가져온 스킬 원본은 포함하지 않습니다.

## Principle

바퀴를 재발명하지 않습니다. 기본 스킬이나 외부 스킬이 해결하는 영역은 그대로 쓰고, 사용자 방식에 맞춘 얇은 wrapper나 보강 규칙만 이 저장소에 둡니다.

## Manifests

- `manifests/custom-skills.json`: 이 저장소가 설치하는 커스텀 스킬
- `manifests/base-skills.json`: 커스텀 스킬이 기대하는 베이스 스킬 또는 플러그인

검사:

```bash
python3 ~/kmh-agent-kit/scripts/check-skill-deps.py
```

누락된 베이스 스킬이 있으면 manifest의 `install_hint`를 따릅니다. Codex system skill은 보통 Codex에 기본 포함되므로 복사하지 않습니다.

## Multi-Server Workflow

한 서버에서 스킬을 수정하면:

```bash
cd ~/kmh-agent-kit
git status --short
git add codex/skills manifests docs
git commit -m "Update agent skills"
git push
```

다른 서버에서는:

```bash
cd ~/kmh-agent-kit
git pull --ff-only
./install.sh
```

충돌이 있으면 현재 서버의 미커밋 변경을 먼저 확인하고, 사용자가 만든 변경을 덮어쓰지 않습니다.
