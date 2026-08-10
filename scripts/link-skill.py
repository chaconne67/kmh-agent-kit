#!/usr/bin/env python3
"""프로필에 스킬 링크를 추가/제거한다 (Linux·macOS·Windows 공용).

Windows에서 `ln -s` 없이 프로필 항목을 만들면 git에 일반 파일(mode 100644)로 커밋되고,
그 레포를 clone한 Linux 서버에서는 install.sh가 스킬 폴더가 아니라 경로 문자열 파일을
링크해 설치가 조용히 깨진다. 이 스크립트는 작업트리 표현과 무관하게 git 인덱스에
항상 심링크(mode 120000)로 등록해 그 사고를 막는다.

스킬 원본은 공용이면 skills/common/<이름>, 도메인 전용이면 skills/domains/<도메인>/<이름>에
있다. 이름만 주면 어느 쪽이든 찾아 상대경로를 계산한다.

usage:
  python scripts/link-skill.py add <스킬명> --claude --codex
  python scripts/link-skill.py add <스킬명> --project <프로젝트명>
  python scripts/link-skill.py rm  <스킬명> --claude
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SKILLS = REPO / "skills"


def find_skill(name: str) -> Path | None:
    """스킬 원본 경로. 공용은 skills/common/, 도메인은 skills/domains/<도메인>/ 아래에 있다."""
    common = SKILLS / "common" / name
    if common.is_dir():
        return common
    for domain in sorted((SKILLS / "domains").iterdir()) if (SKILLS / "domains").is_dir() else []:
        if (domain / name).is_dir():
            return domain / name
    return None


def git(*args: str, capture: bool = False) -> str:
    result = subprocess.run(
        ["git", "-C", str(REPO), *args],
        check=True,
        text=True,
        stdout=subprocess.PIPE if capture else None,
    )
    return result.stdout.strip() if capture else ""


def profile_dirs(args: argparse.Namespace) -> list[Path]:
    dirs: list[Path] = []
    if args.claude:
        dirs.append(REPO / "claude" / "skills")
    if args.codex:
        dirs.append(REPO / "codex" / "skills")
    for project in args.project or []:
        dirs.append(REPO / "projects" / project / "skills")
    return dirs


def add(skill: str, source: Path, profile: Path) -> None:
    rel = os.path.relpath(source, profile).replace(os.sep, "/")
    link = profile / skill
    profile.mkdir(parents=True, exist_ok=True)
    if link.exists() or link.is_symlink():
        link.unlink()

    # 작업트리 표현: 심링크가 가능하면 심링크, 아니면 git이 core.symlinks=false로
    # 체크아웃할 때와 같은 형태(개행 없는 경로 한 줄)로 둔다.
    try:
        link.symlink_to(rel, target_is_directory=True)
    except OSError:
        with open(link, "w", encoding="utf-8", newline="") as handle:
            handle.write(rel)

    blob = subprocess.run(
        ["git", "-C", str(REPO), "hash-object", "-w", "--stdin"],
        input=rel, text=True, check=True, stdout=subprocess.PIPE,
    ).stdout.strip()
    index_path = str((profile / skill).relative_to(REPO)).replace(os.sep, "/")
    git("update-index", "--add", "--cacheinfo", f"120000,{blob},{index_path}")
    print(f"linked  {index_path} -> {rel}")


def remove(skill: str, profile: Path) -> None:
    link = profile / skill
    index_path = str(link.relative_to(REPO)).replace(os.sep, "/")
    if link.exists() or link.is_symlink():
        link.unlink()
    git("rm", "--cached", "--quiet", "--ignore-unmatch", index_path)
    print(f"unlinked {index_path}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["add", "rm"])
    parser.add_argument("skill")
    parser.add_argument("--claude", action="store_true", help="Claude 전역 프로필")
    parser.add_argument("--codex", action="store_true", help="Codex 전역 프로필")
    parser.add_argument("--project", action="append", help="프로젝트 프로필명 (반복 가능)")
    args = parser.parse_args()

    source = find_skill(args.skill)
    if source is None:
        print(f"[error] '{args.skill}' 스킬 없음 (skills/common/ 또는 skills/domains/*/ 아래여야 함)", file=sys.stderr)
        return 1

    targets = profile_dirs(args)
    if not targets:
        print("[error] 프로필을 하나 이상 지정하세요 (--claude / --codex / --project)", file=sys.stderr)
        return 1

    # 도메인 스킬은 그 도메인의 프로젝트 프로필에만 배치한다 (check-skill-deps.py가 강제).
    is_domain = source.parent.parent.name == "domains"
    for profile in targets:
        if args.action == "add":
            if is_domain and profile.parent.parent.name != "projects":
                print(f"[error] '{args.skill}'은 도메인 스킬({source.parent.name})이라 전역 프로필에 둘 수 없다 "
                      f"— --project {source.parent.name} 을 쓰라", file=sys.stderr)
                return 1
            add(args.skill, source, profile)
        else:
            remove(args.skill, profile)

    print("다음: python scripts/check-skill-deps.py 로 검증 후 커밋")
    return 0


if __name__ == "__main__":
    sys.exit(main())
