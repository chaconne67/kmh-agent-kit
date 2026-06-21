#!/usr/bin/env python3
"""Validate the distilled Exdigm Agent API surface manifest."""

from __future__ import annotations

import json
import subprocess
import sys
from collections import Counter
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
MANIFEST = REPO / "manifests" / "exdigm-agent-api-surface.json"


def _catalog_route_names(exdigm_root: Path) -> set[str]:
    command = [
        "uv",
        "run",
        "python",
        "manage.py",
        "shell",
        "-c",
        (
            "from accounts.services.hermes_provisioning import "
            "_agent_api_catalog_dict; "
            "import json; "
            "print(json.dumps([r['name'] for r in "
            "_agent_api_catalog_dict()['routes']]))"
        ),
    ]
    proc = subprocess.run(
        command,
        cwd=exdigm_root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip())
    lines = [line for line in proc.stdout.splitlines() if line.startswith("[")]
    if not lines:
        raise RuntimeError("Agent API catalog route list was not emitted")
    return set(json.loads(lines[-1]))


def main() -> int:
    exdigm_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / "exdigm"
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    route_classes = manifest.get("route_classes") or {}
    classified = [
        route_name
        for routes in route_classes.values()
        for route_name in routes
    ]
    counts = Counter(classified)
    duplicates = sorted(route for route, count in counts.items() if count > 1)
    catalog_routes = _catalog_route_names(exdigm_root)
    classified_routes = set(classified)
    missing = sorted(catalog_routes - classified_routes)
    stale = sorted(classified_routes - catalog_routes)
    report = {
        "ok": not duplicates and not missing and not stale,
        "catalog_routes": len(catalog_routes),
        "classified_routes": len(classified_routes),
        "class_counts": {
            class_name: len(routes)
            for class_name, routes in route_classes.items()
        },
        "duplicates": duplicates,
        "missing": missing,
        "stale": stale,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
