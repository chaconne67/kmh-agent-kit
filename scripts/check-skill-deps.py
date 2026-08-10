#!/usr/bin/env python3
"""kmh-agent-kit 구조 검증.

- skills/: 공용은 skills/common/<이름>, 도메인 전용은 skills/domains/<도메인>/<이름>에만
  있는지 (그 두 층 밖의 스킬 폴더는 분류되지 않은 것으로 본다) + 각 폴더에 SKILL.md가 있는지
- 프로필(claude/skills, codex/skills, projects/*/skills): 모든 항목이 스킬 원본을
  가리키는 링크이고 해상되는지
  (Windows에서 core.symlinks=false로 clone하면 git이 심링크를 경로 문자열이 담긴
   일반 파일로 체크아웃한다 — 두 표현 모두 유효한 링크로 인정한다)
- 배치 규칙: 도메인 스킬은 전역 프로필(claude/codex)에 둘 수 없고, 프로젝트 프로필에만
  둔다. 한 프로젝트 프로필에 두 도메인이 섞이면 경고한다.
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


def read_profile_link(entry: Path) -> str | None:
    """프로필 항목이 가리키는 경로 문자열. 링크가 아니면 None.

    심링크를 만들 수 없는 clone(Windows, core.symlinks=false)에서는 git이 링크 대상
    경로만 담긴 한 줄짜리 일반 파일로 체크아웃하므로 그 표현도 링크로 읽는다.
    """
    if entry.is_symlink():
        return os.readlink(entry)
    if entry.is_file() and entry.stat().st_size < 4096:
        text = entry.read_text(encoding="utf-8", errors="replace").strip()
        if text and "\n" not in text and text.startswith(".."):
            return text
    return None


def collect_skills() -> tuple[dict[str, Path], dict[str, str]]:
    """스킬 원본 경로와 도메인 소속. 도메인이 없으면(공용) domain 사전에 없다."""
    paths: dict[str, Path] = {}
    domains: dict[str, str] = {}

    common = SKILLS / "common"
    if common.is_dir():
        for entry in sorted(common.iterdir()):
            if entry.is_dir():
                paths[entry.name] = entry

    domains_root = SKILLS / "domains"
    if domains_root.is_dir():
        for domain in sorted(domains_root.iterdir()):
            if not domain.is_dir():
                continue
            for entry in sorted(domain.iterdir()):
                if not entry.is_dir():
                    continue
                if entry.name in paths:
                    errors.append(f"skills: '{entry.name}'이 common과 domains/{domain.name} 양쪽에 있음")
                    continue
                paths[entry.name] = entry
                domains[entry.name] = domain.name

    # common/·domains/ 밖에 남은 스킬 폴더는 분류가 안 된 것이다.
    for entry in sorted(SKILLS.iterdir()) if SKILLS.is_dir() else []:
        if entry.is_dir() and entry.name not in ("common", "domains"):
            errors.append(f"skills/{entry.name}: 미분류 — skills/common/ 또는 skills/domains/<도메인>/ 아래로 옮겨라")

    return paths, domains


def profile_names(profile_dir: Path, skill_paths: dict[str, Path]) -> set[str]:
    names: set[str] = set()
    if not profile_dir.is_dir():
        return names
    for entry in sorted(profile_dir.iterdir()):
        link = read_profile_link(entry)
        if link is None:
            errors.append(f"{entry}: 링크가 아님 (프로필 항목은 스킬 원본을 가리키는 상대 심링크여야 함)")
            continue
        if os.path.isabs(link):
            errors.append(f"{entry}: 절대경로 링크 (다른 clone에서 깨짐 — 상대경로여야 함)")
            continue
        expected_path = skill_paths.get(entry.name)
        if expected_path is None:
            errors.append(f"{entry}: 대상 없음 (그런 이름의 스킬이 skills/에 없다)")
            continue
        target = (entry.parent / link).resolve()
        expected = expected_path.resolve()
        if target != expected:
            errors.append(f"{entry}: {expected}가 아니라 {target}을 가리킴")
            continue
        names.add(entry.name)
    return names


def main() -> int:
    skill_paths, skill_domains = collect_skills()
    skill_names = set(skill_paths)
    for name in sorted(skill_names):
        if not (skill_paths[name] / "SKILL.md").is_file():
            errors.append(f"{skill_paths[name].relative_to(REPO)}: SKILL.md 없음")

    global_names = {tool: profile_names(path, skill_paths) for tool, path in GLOBAL_PROFILES.items()}
    for tool, names in global_names.items():
        for name in sorted(n for n in names if n in skill_domains):
            errors.append(
                f"{tool} 프로필: '{name}'은 도메인 스킬({skill_domains[name]})이라 전역에 둘 수 없다 "
                f"— projects/{skill_domains[name]}/skills/로 옮겨라"
            )

    project_names: dict[str, set[str]] = {}
    projects_dir = REPO / "projects"
    if projects_dir.is_dir():
        for proj in sorted(projects_dir.iterdir()):
            if (proj / "skills").is_dir():
                project_names[proj.name] = profile_names(proj / "skills", skill_paths)

    # 프로젝트 프로필에 여러 도메인이 섞이면 그 프로젝트를 여는 것만으로 남의 도메인 스킬이 뜬다.
    for proj, names in sorted(project_names.items()):
        mixed = sorted({skill_domains[n] for n in names if n in skill_domains})
        if len(mixed) > 1:
            warnings.append(f"projects/{proj}: 도메인이 섞임 ({', '.join(mixed)}) — 의도한 것인지 확인하라")

    linked_anywhere: set[str] = set()
    for names in list(global_names.values()) + list(project_names.values()):
        linked_anywhere |= names
    for name in sorted(skill_names - linked_anywhere):
        warnings.append(f"{skill_paths[name].relative_to(REPO)}: 어느 프로필에도 링크되지 않음 (고아 스킬)")

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
