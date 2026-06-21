#!/usr/bin/env python3
"""Validate Exdigm GBrain/code_map linking manifest."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
MANIFEST = REPO / "manifests" / "exdigm-knowledge-map.json"


def main() -> int:
    exdigm_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / "exdigm"
    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))
    missing: list[dict[str, str]] = []

    for entry in entries:
        entrypoints = entry.get("entrypoints", [])
        if len(entrypoints) > 8:
            missing.append({"domain": entry["domain"], "kind": "too_many_entrypoints", "value": str(len(entrypoints))})
        if not entry.get("distillation_note"):
            missing.append({"domain": entry["domain"], "kind": "missing_distillation_note", "value": "distillation_note"})
        for path in entry.get("entrypoints", []):
            if path.endswith("/"):
                candidate = exdigm_root / path
            else:
                candidate = exdigm_root / path
            if not candidate.exists() and "*" not in path:
                missing.append({"domain": entry["domain"], "kind": "entrypoint", "value": path})
        for topic in entry.get("code_map_topics", []):
            proc = subprocess.run(
                ["uv", "run", "python", "-m", "tools.code_map.impact", "--topic", topic],
                cwd=exdigm_root,
                text=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                check=False,
            )
            if proc.returncode != 0:
                missing.append({"domain": entry["domain"], "kind": "code_map_topic", "value": topic})

    if missing:
        print(json.dumps({"ok": False, "missing": missing}, ensure_ascii=False, indent=2))
        return 1
    print(json.dumps({"ok": True, "entries": len(entries)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
