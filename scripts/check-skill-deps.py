#!/usr/bin/env python3
"""kmh-agent-kit 구조 검증.

- skills/: 모든 스킬 폴더에 SKILL.md가 있는지
- 프로필(claude/skills, codex/skills, projects/*/skills): 모든 항목이
  skills/<이름>을 가리키는 심링크이고 해상되는지
- manifests/skills.json: depends_on의 모든 이름이 skills/에 존재하고,
  프로필에 링크된 스킬의 의존 스킬이 같은 가시 범위에 있는지
  (전역 프로필은 같은 프로필 안, 프로젝트 프로필은 프로젝트+양쪽 전역)
- manifests/base-skills.json: Codex system skill 존재 확인 (있을 때만)
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

HOME = Path.home()
REPO = Path(__file__).resolve().parents[1]
CODEX_HOME = Path(os.environ.get("CODEX_HOME", HOME / ".codex"))
SKILLS = REPO / "skills"
GLOBAL_PROFILES = {"claude": REPO / "claude" / "skills", "codex": REPO / "codex" / "skills"}

errors: list[str] = []
warnings: list[str] = []


def profile_names(profile_dir: Path) -> set[str]:
    names: set[str] = set()
    if not profile_dir.is_dir():
        return names
    for entry in sorted(profile_dir.iterdir()):
        if not entry.is_symlink():
            errors.append(f"{entry}: 심링크가 아님 (프로필 항목은 skills/를 가리키는 링크여야 함)")
            continue
        if os.path.isabs(os.readlink(entry)):
            errors.append(f"{entry}: 절대경로 링크 (다른 clone에서 깨짐 — 상대경로여야 함)")
            continue
        target = (entry.parent / os.readlink(entry)).resolve()
        expected = (SKILLS / entry.name).resolve()
        if target != expected:
            errors.append(f"{entry}: {expected}가 아니라 {target}을 가리킴")
            continue
        if not target.is_dir():
            errors.append(f"{entry}: 대상 없음 (skills/{entry.name} 부재)")
            continue
        names.add(entry.name)
    return names


def main() -> int:
    skill_names = {p.name for p in SKILLS.iterdir() if p.is_dir()} if SKILLS.is_dir() else set()
    for name in sorted(skill_names):
        if not (SKILLS / name / "SKILL.md").is_file():
            errors.append(f"skills/{name}: SKILL.md 없음")

    global_names = {tool: profile_names(path) for tool, path in GLOBAL_PROFILES.items()}

    project_names: dict[str, set[str]] = {}
    projects_dir = REPO / "projects"
    if projects_dir.is_dir():
        for proj in sorted(projects_dir.iterdir()):
            if (proj / "skills").is_dir():
                project_names[proj.name] = profile_names(proj / "skills")

    linked_anywhere: set[str] = set()
    for names in list(global_names.values()) + list(project_names.values()):
        linked_anywhere |= names
    for name in sorted(skill_names - linked_anywhere):
        warnings.append(f"skills/{name}: 어느 프로필에도 링크되지 않음 (고아 스킬)")

    manifest = json.loads((REPO / "manifests" / "skills.json").read_text(encoding="utf-8"))
    depends_on: dict[str, list[str]] = manifest.get("depends_on", {})
    for name, deps in depends_on.items():
        for missing in [d for d in [name, *deps] if d not in skill_names]:
            errors.append(f"manifests/skills.json: '{missing}' 스킬이 skills/에 없음")

    for tool, names in global_names.items():
        for name in sorted(names):
            for dep in depends_on.get(name, []):
                if dep not in names:
                    errors.append(f"{tool} 프로필: {name}의 의존 스킬 {dep}이 같은 프로필에 없음")
    for proj, names in project_names.items():
        visible = names | global_names["claude"] | global_names["codex"]
        for name in sorted(names):
            for dep in depends_on.get(name, []):
                if dep not in visible:
                    errors.append(f"projects/{proj}: {name}의 의존 스킬 {dep}이 프로젝트/전역 어디에도 없음")

    base_manifest = REPO / "manifests" / "base-skills.json"
    if base_manifest.is_file() and (CODEX_HOME / "skills").is_dir():
        system_dir = CODEX_HOME / "skills" / ".system"
        for item in json.loads(base_manifest.read_text(encoding="utf-8")):
            if item.get("kind") == "system_skill" and not (system_dir / str(item["name"])).is_dir():
                warnings.append(f"Codex system skill 부재: {item['name']} — {item.get('install_hint', '')}")

    for line in warnings:
        print(f"[warn] {line}")
    for line in errors:
        print(f"[error] {line}")
    if errors:
        print(f"실패: 오류 {len(errors)}건")
        return 1
    summary = f"통과: 스킬 {len(skill_names)}개, 프로필 claude {len(global_names['claude'])} / codex {len(global_names['codex'])}"
    summary += "".join(f" / {p} {len(n)}" for p, n in sorted(project_names.items()))
    print(summary)
    return 0


if __name__ == "__main__":
    sys.exit(main())
