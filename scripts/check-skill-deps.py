#!/usr/bin/env python3
"""Check custom skill dependency declarations against installed Codex skills."""

from __future__ import annotations

import json
import os
from pathlib import Path


HOME = Path.home()
REPO = Path(__file__).resolve().parents[1]
CODEX_HOME = Path(os.environ.get("CODEX_HOME", HOME / ".codex"))
CUSTOM_MANIFEST = REPO / "manifests" / "custom-skills.json"
BASE_MANIFEST = REPO / "manifests" / "base-skills.json"


def load_json(path: Path) -> list[dict[str, object]]:
    return json.loads(path.read_text(encoding="utf-8"))


def installed_skill_names() -> set[str]:
    skills_dir = CODEX_HOME / "skills"
    if not skills_dir.exists():
        return set()
    return {path.name for path in skills_dir.iterdir() if path.is_dir()}


def main() -> int:
    custom = load_json(CUSTOM_MANIFEST)
    base = {item["name"]: item for item in load_json(BASE_MANIFEST)}
    custom_names = {str(item["name"]) for item in custom}
    installed = installed_skill_names()
    missing: list[dict[str, object]] = []

    for skill in custom:
        for dep in skill.get("depends_on", []):
            dep_name = str(dep)
            if dep_name in installed:
                continue
            if dep_name in custom_names:
                missing.append(
                    {
                        "skill": skill["name"],
                        "missing": dep_name,
                        "source": "kmh-agent-kit custom skill",
                        "install_hint": "./install.sh should install this dependency from codex/skills.",
                    }
                )
            elif dep_name in base:
                missing.append(
                    {
                        "skill": skill["name"],
                        "missing": dep_name,
                        "source": base[dep_name].get("source"),
                        "install_hint": base[dep_name].get("install_hint"),
                    }
                )
            else:
                missing.append(
                    {
                        "skill": skill["name"],
                        "missing": dep_name,
                        "source": "unknown",
                        "install_hint": "Add this dependency to manifests/base-skills.json or codex/skills.",
                    }
                )

    if missing:
        print(json.dumps({"ok": False, "missing": missing}, ensure_ascii=False, indent=2))
        return 1

    print(json.dumps({"ok": True, "message": "No declared base skill dependencies are missing."}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
