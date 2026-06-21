#!/usr/bin/env python3
"""Daily GBrain memory distillation wrapper.

This script is glue around GBrain's own dream-cycle distillation engine.
It does not implement a competing semantic classifier. It converts Codex
JSONL session logs into transcript corpus files, runs `gbrain dream`, and
keeps the operator-review ledger used by Codex session bootstrap.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


HOME = Path.home()
CODEX_HOME = Path(os.environ.get("CODEX_HOME", HOME / ".codex"))
GBRAIN_HOME = Path(os.environ.get("GBRAIN_HOME", HOME / ".gbrain"))
GBRAIN_CLI = Path(os.environ.get("GBRAIN_CLI", HOME / ".bun/bin/gbrain"))
EXDIGM_ENV_PATH = Path(os.environ.get("KMH_AGENT_ENV_FILE", HOME / "exdigm" / ".env"))
REPORTS_DIR = GBRAIN_HOME / "reports"
LEDGER_PATH = REPORTS_DIR / "index.json"
BRAIN_DIR = GBRAIN_HOME / "brain"
TRANSCRIPT_DIR = GBRAIN_HOME / "transcripts" / "codex"
GBRAIN_DREAM_MODEL = os.environ.get("GBRAIN_DREAM_MODEL", "openrouter:google/gemini-3-flash-preview")
KST = dt.timezone(dt.timedelta(hours=9), "Asia/Seoul")

SECRET_PATTERNS = [
    re.compile(r"(?i)(api[_-]?key|token|password|secret)\s*[:=]\s*\S+"),
    re.compile(r"Bearer\s+[A-Za-z0-9._~+/-]+"),
]


def local_date_from_timestamp(value: str | None) -> str | None:
    if not value:
        return None
    raw = value.replace("Z", "+00:00")
    try:
        parsed = dt.datetime.fromisoformat(raw)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(KST).date().isoformat()


def default_target_date() -> str:
    return (dt.datetime.now(KST).date() - dt.timedelta(days=1)).isoformat()


def today() -> str:
    return dt.datetime.now(KST).date().isoformat()


def now_iso() -> str:
    return dt.datetime.now(KST).isoformat(timespec="seconds")


def run_env() -> dict[str, str]:
    env = dict(os.environ)
    gemini_key = load_exdigm_env_value("GEMINI_API_KEY") or env.get("GEMINI_API_KEY", "")
    openrouter_key = load_exdigm_env_value("OPENROUTER_API_KEY") or env.get("OPENROUTER_API_KEY", "")
    if gemini_key and not env.get("GOOGLE_GENERATIVE_AI_API_KEY"):
        env["GOOGLE_GENERATIVE_AI_API_KEY"] = gemini_key
    if openrouter_key:
        env["OPENROUTER_API_KEY"] = openrouter_key
    bun_bin = os.environ.get("BUN_BIN", f"{HOME}/.bun/bin")
    env["PATH"] = f"{bun_bin}:" + env.get("PATH", "")
    for key in ["DATABASE_URL", "OPENAI_API_KEY"]:
        env.pop(key, None)
    return env


def load_exdigm_env_value(target_key: str) -> str:
    if not EXDIGM_ENV_PATH.exists():
        return ""
    try:
        lines = EXDIGM_ENV_PATH.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return ""
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        if key.strip() == target_key:
            return value.strip().strip('"').strip("'")
    return ""


def redact(text: str) -> str:
    redacted = text
    for pattern in SECRET_PATTERNS:
        redacted = pattern.sub("[REDACTED]", redacted)
    return redacted


def iter_codex_jsonl_files() -> list[Path]:
    candidates: list[Path] = []
    for root in [CODEX_HOME / "archived_sessions", CODEX_HOME / "sessions"]:
        if root.exists():
            candidates.extend(root.rglob("*.jsonl"))
    history = CODEX_HOME / "history.jsonl"
    if history.exists():
        candidates.append(history)
    return sorted(set(candidates))


def extract_user_messages(target_date: str) -> list[dict[str, Any]]:
    messages: list[dict[str, Any]] = []
    for path in iter_codex_jsonl_files():
        try:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue
        for line_no, line in enumerate(lines, start=1):
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if local_date_from_timestamp(obj.get("timestamp")) != target_date:
                continue
            payload = obj.get("payload") or {}
            text = None
            if obj.get("type") == "event_msg" and payload.get("type") == "user_message":
                text = payload.get("message")
            if not text or text.startswith("# AGENTS.md instructions"):
                continue
            messages.append(
                {
                    "timestamp": obj.get("timestamp"),
                    "path": str(path),
                    "line": line_no,
                    "text": redact(text).strip(),
                }
            )
    return messages


def transcript_path_for(target_date: str, messages: list[dict[str, Any]]) -> Path:
    digest = hashlib.sha1(
        "\n".join(f"{m['timestamp']} {m['source'] if 'source' in m else m['path']}:{m['line']}" for m in messages).encode("utf-8")
    ).hexdigest()[:8]
    return TRANSCRIPT_DIR / f"{target_date}-codex-session-{digest}.txt"


def render_transcript(target_date: str, messages: list[dict[str, Any]]) -> str:
    lines = [
        f"Codex session transcript for GBrain dream synthesis",
        f"Date: {target_date} Asia/Seoul",
        "",
        "Purpose:",
        "- Distill durable agent-evolution lessons, work rules, project rationale, user feedback, and repeated-correction patterns.",
        "- Prefer GBrain dream's built-in worth-processing and pattern synthesis judgment.",
        "- Do not preserve secrets or raw transcript details that are not reusable.",
        "",
        "Operator intent:",
        "- Reduce repeated explanations across Codex, Claude Code, and Hermes sessions.",
        "- Capture durable lessons that should change future agent behavior.",
        "- Keep routine one-off operations out of long-term memory.",
        "",
    ]
    for i, msg in enumerate(messages, start=1):
        lines.extend(
            [
                f"## User message {i}",
                f"Timestamp: {msg['timestamp']}",
                f"Source: {msg['path']}:{msg['line']}",
                "",
                msg["text"],
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def write_transcript(target_date: str) -> tuple[Path | None, int]:
    messages = extract_user_messages(target_date)
    if not messages:
        return None, 0
    TRANSCRIPT_DIR.mkdir(parents=True, exist_ok=True)
    for old_path in TRANSCRIPT_DIR.glob(f"{target_date}-codex-session-*.txt"):
        old_path.unlink()
    path = transcript_path_for(target_date, messages)
    path.write_text(render_transcript(target_date, messages), encoding="utf-8")
    return path, len(messages)


def gbrain_available() -> bool:
    return GBRAIN_CLI.exists()


def run_gbrain(args: list[str], timeout: int = 120) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(GBRAIN_CLI), *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        env=run_env(),
    )


def configure_gbrain() -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    for key, value in [
        ("dream.synthesize.session_corpus_dir", str(TRANSCRIPT_DIR)),
        ("dream.synthesize.enabled", "true"),
        ("models.dream.synthesize_verdict", GBRAIN_DREAM_MODEL),
        ("models.dream.synthesize", GBRAIN_DREAM_MODEL),
        ("models.dream.patterns", GBRAIN_DREAM_MODEL),
    ]:
        proc = run_gbrain(["config", "set", key, value])
        verify = run_gbrain(["config", "get", key]) if proc.returncode == 0 else None
        results.append(
            {
                "key": key,
                "value": value,
                "returncode": proc.returncode,
                "stdout": proc.stdout.strip(),
                "stderr": proc.stderr.strip(),
                "verified": verify.returncode == 0 and verify.stdout.strip() == value if verify else False,
                "verify_stdout": verify.stdout.strip() if verify else "",
                "verify_stderr": verify.stderr.strip() if verify else "",
            }
        )
    return results


def run_dream(target_date: str, dry_run: bool) -> dict[str, Any]:
    if not gbrain_available():
        return {"ran": False, "reason": "gbrain CLI unavailable"}
    BRAIN_DIR.mkdir(parents=True, exist_ok=True)
    config_results = configure_gbrain()
    if any(not item.get("verified") for item in config_results):
        return {
            "ran": True,
            "dry_run": dry_run,
            "config": config_results,
            "synthesize": {
                "returncode": None,
                "stdout": "",
                "stderr": "GBrain model/config verification failed; dream synthesize was not run.",
                "json": None,
            },
            "patterns": None,
        }
    synth_args = ["dream", "--phase", "synthesize", "--json", "--dir", str(BRAIN_DIR), "--date", target_date]
    if dry_run:
        synth_args.insert(1, "--dry-run")
    synth = run_gbrain(synth_args, timeout=900)

    patterns: subprocess.CompletedProcess[str] | None = None
    if not dry_run and synth.returncode == 0:
        patterns = run_gbrain(["dream", "--phase", "patterns", "--json", "--dir", str(BRAIN_DIR)], timeout=900)

    return {
        "ran": True,
        "dry_run": dry_run,
        "config": config_results,
        "synthesize": command_result(synth),
        "patterns": command_result(patterns) if patterns else None,
    }


def command_result(proc: subprocess.CompletedProcess[str] | None) -> dict[str, Any] | None:
    if proc is None:
        return None
    parsed = parse_json_payload(proc.stdout)
    return {
        "returncode": proc.returncode,
        "stdout": proc.stdout.strip(),
        "stderr": proc.stderr.strip(),
        "json": parsed,
    }


def parse_json_payload(output: str) -> Any:
    text = output.strip()
    if not text:
        return None
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        return None
    try:
        return json.loads(text[start : end + 1])
    except json.JSONDecodeError:
        return None


def load_ledger() -> dict[str, Any]:
    if not LEDGER_PATH.exists():
        return {"reports": {}}
    try:
        return json.loads(LEDGER_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"reports": {}}


def save_ledger(ledger: dict[str, Any]) -> None:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    temp = LEDGER_PATH.with_suffix(".json.tmp")
    temp.write_text(json.dumps(ledger, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temp.replace(LEDGER_PATH)


def dream_totals(dream: dict[str, Any]) -> dict[str, Any]:
    synth_json = ((dream.get("synthesize") or {}).get("json") or {})
    totals = synth_json.get("totals") if isinstance(synth_json, dict) else None
    if not isinstance(totals, dict):
        return {}
    return {
        "transcripts_processed": totals.get("transcripts_processed", 0),
        "synth_pages_written": totals.get("synth_pages_written", 0),
        "patterns_written": totals.get("patterns_written", 0),
    }


def dream_blockers(dream: dict[str, Any]) -> list[str]:
    blockers: list[str] = []
    for item in dream.get("config") or []:
        if isinstance(item, dict) and not item.get("verified"):
            detail = compact_multiline(item.get("verify_stderr") or item.get("stderr") or item.get("verify_stdout") or item.get("stdout") or "")
            blockers.append(f"config verification failed for {item.get('key')}: {detail}")
    synth = dream.get("synthesize") or {}
    if synth.get("returncode") not in {None, 0}:
        blockers.append(f"synthesize command failed: {compact_multiline(synth.get('stderr', ''))}")
    synth_json = synth.get("json") or {}
    phases = synth_json.get("phases") if isinstance(synth_json, dict) else []
    if not isinstance(phases, list):
        return blockers
    for phase in phases:
        if not isinstance(phase, dict):
            continue
        details = phase.get("details") or {}
        verdicts = details.get("verdicts") if isinstance(details, dict) else []
        if not isinstance(verdicts, list):
            continue
        for verdict in verdicts:
            if not isinstance(verdict, dict):
                continue
            for reason in verdict.get("reasons") or []:
                if not isinstance(reason, str):
                    continue
                if "no configured provider" in reason or "gateway error" in reason:
                    blockers.append(reason)
    return sorted(set(blockers))


def render_report(target_date: str, transcript: Path | None, message_count: int, dream: dict[str, Any]) -> str:
    totals = dream_totals(dream)
    blockers = dream_blockers(dream)
    synth = dream.get("synthesize") or {}
    patterns = dream.get("patterns") or {}
    lines = [
        "---",
        "type: report",
        f"title: GBrain Dream Distillation {target_date}",
        f"created: '{now_iso()}'",
        "page_type: report",
        "tags:",
        "  - gbrain",
        "  - memory-distillation",
        "  - dream-cycle",
        "  - review-required",
        "---",
        "",
        f"# GBrain Dream Distillation Report - {target_date}",
        "",
        "This report is an operator-review artifact around GBrain's built-in dream cycle.",
        "Semantic distillation is delegated to `gbrain dream --phase synthesize` and `gbrain dream --phase patterns`.",
        "",
        "## Inputs",
        "",
        f"- Transcript file: `{transcript}`" if transcript else "- Transcript file: none",
        f"- User messages extracted: {message_count}",
        f"- Brain dir: `{BRAIN_DIR}`",
        f"- Transcript corpus dir: `{TRANSCRIPT_DIR}`",
        "",
        "## Dream Result",
        "",
        f"- Dream ran: {dream.get('ran')}",
        f"- Dry run: {dream.get('dry_run')}",
        f"- Transcripts processed: {totals.get('transcripts_processed', 0)}",
        f"- Synth pages written: {totals.get('synth_pages_written', 0)}",
        f"- Patterns written: {totals.get('patterns_written', 0)}",
        f"- Blockers: {len(blockers)}",
        "",
        "## Blockers",
        "",
        *(f"- {blocker}" for blocker in blockers),
        "" if blockers else "- None",
        "",
        "## Synthesize Command",
        "",
        f"- Return code: {synth.get('returncode')}",
        f"- Stderr: `{compact_multiline(synth.get('stderr', ''))}`",
        "",
        "```json",
        json.dumps(synth.get("json") or synth.get("stdout") or {}, ensure_ascii=False, indent=2)[:12000],
        "```",
        "",
        "## Patterns Command",
        "",
        f"- Return code: {patterns.get('returncode') if patterns else 'not run'}",
        f"- Stderr: `{compact_multiline(patterns.get('stderr', '')) if patterns else ''}`",
    ]
    if patterns:
        lines.extend(["", "```json", json.dumps(patterns.get("json") or patterns.get("stdout") or {}, ensure_ascii=False, indent=2)[:12000], "```"])
    return "\n".join(lines).rstrip() + "\n"


def compact_multiline(text: str, limit: int = 500) -> str:
    one_line = re.sub(r"\s+", " ", text or "").strip()
    if len(one_line) <= limit:
        return one_line
    return one_line[: limit - 1].rstrip() + "…"


def write_gbrain_report(slug: str, report_path: Path) -> None:
    if not gbrain_available():
        return
    subprocess.run(
        [str(GBRAIN_CLI), "capture", "--file", str(report_path), "--slug", slug, "--type", "report", "--quiet"],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=30,
        env=run_env(),
    )


def generate(args: argparse.Namespace) -> int:
    target_date = args.date or default_target_date()
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    transcript, message_count = write_transcript(target_date)

    dry_run = args.dream_dry_run
    if transcript is None:
        dream = {"ran": False, "dry_run": dry_run, "reason": "no Codex user messages for date"}
    elif args.no_dream:
        dream = {"ran": False, "dry_run": dry_run, "reason": "--no-dream"}
    else:
        dream = run_dream(target_date, dry_run=dry_run)

    report_path = REPORTS_DIR / f"{target_date}-memory-distillation.md"
    slug = f"report/gbrain-distillation-{target_date}"
    report_path.write_text(render_report(target_date, transcript, message_count, dream), encoding="utf-8")
    if not args.no_gbrain:
        write_gbrain_report(slug, report_path)

    summary = {
        "messages_extracted": message_count,
        "transcript_path": str(transcript) if transcript else None,
        **dream_totals(dream),
        "blockers": dream_blockers(dream),
        "dream_ran": dream.get("ran", False),
        "dream_dry_run": dry_run,
    }
    ledger = load_ledger()
    existing = ledger.setdefault("reports", {}).get(target_date, {})
    status = existing.get("status")
    if message_count == 0:
        status = "skipped"
    elif status not in {"reviewed", "applied", "skipped"}:
        status = "unchecked"
    ledger["reports"][target_date] = {
        **existing,
        "report_path": str(report_path),
        "gbrain_slug": slug,
        "generated_at": now_iso(),
        "status": status,
        "reviewed_at": existing.get("reviewed_at"),
        "review_decision": existing.get("review_decision"),
        "last_prompted_date": existing.get("last_prompted_date"),
        "summary": summary,
    }
    save_ledger(ledger)
    print(json.dumps({"date": target_date, "report_path": str(report_path), "summary": summary}, ensure_ascii=False))
    return 2 if summary["blockers"] else 0


def pending_reports(ledger: dict[str, Any], today_value: str) -> list[tuple[str, dict[str, Any]]]:
    reports = ledger.get("reports", {})
    return sorted(
        (date, data)
        for date, data in reports.items()
        if date < today_value and data.get("status") == "unchecked"
    )


def check_pending(args: argparse.Namespace) -> int:
    today_value = args.today or today()
    ledger = load_ledger()
    pending = pending_reports(ledger, today_value)
    if not pending:
        print(json.dumps({"pending": False, "message": "No unchecked memory distillation reports."}, ensure_ascii=False))
        return 0
    date, data = pending[0]
    already_prompted = data.get("last_prompted_date") == today_value
    message = (
        f"{date} GBrain dream distillation 리포트가 미확인 상태입니다. "
        f"리포트: {data.get('report_path')}. 지금 리뷰할까요?"
    )
    if already_prompted:
        print(json.dumps({"pending": True, "prompt": False, "date": date, "message": "Already prompted today."}, ensure_ascii=False))
        return 0
    if not args.dry_run:
        data["last_prompted_date"] = today_value
        ledger["reports"][date] = data
        save_ledger(ledger)
    print(json.dumps({"pending": True, "prompt": True, "date": date, "message": message}, ensure_ascii=False))
    return 0


def mark(args: argparse.Namespace) -> int:
    ledger = load_ledger()
    report = ledger.setdefault("reports", {}).get(args.date)
    if not report:
        print(f"No report for {args.date}", file=sys.stderr)
        return 1
    report["status"] = args.status
    if args.status in {"reviewed", "applied", "skipped"}:
        report["reviewed_at"] = now_iso()
    if args.decision:
        report["review_decision"] = args.decision
    ledger["reports"][args.date] = report
    save_ledger(ledger)
    print(json.dumps({"date": args.date, "status": args.status}, ensure_ascii=False))
    return 0


def list_reports(_: argparse.Namespace) -> int:
    print(json.dumps(load_ledger(), ensure_ascii=False, indent=2))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="GBrain dream distillation wrapper")
    sub = parser.add_subparsers(dest="command", required=True)

    generate_parser = sub.add_parser("generate", help="Generate a daily GBrain dream distillation report")
    generate_parser.add_argument("--date", help="Target local date YYYY-MM-DD. Defaults to yesterday.")
    generate_parser.add_argument("--no-gbrain", action="store_true", help="Do not write the report into GBrain.")
    generate_parser.add_argument("--no-dream", action="store_true", help="Only create the transcript/report; do not run GBrain dream.")
    generate_parser.add_argument(
        "--dream-dry-run",
        action="store_true",
        help="Run GBrain synthesize in dry-run mode. Note: GBrain dry-run may still call its cheap verdict model.",
    )
    generate_parser.set_defaults(func=generate)

    check_parser = sub.add_parser("check-pending", help="Check unchecked reports and prompt at most once per day")
    check_parser.add_argument("--today", help="Override local today YYYY-MM-DD, for tests.")
    check_parser.add_argument("--dry-run", action="store_true", help="Do not update last_prompted_date.")
    check_parser.set_defaults(func=check_pending)

    mark_parser = sub.add_parser("mark", help="Mark a report status")
    mark_parser.add_argument("date")
    mark_parser.add_argument("--status", required=True, choices=["unchecked", "reviewed", "applied", "skipped"])
    mark_parser.add_argument("--decision", help="Optional review decision note")
    mark_parser.set_defaults(func=mark)

    list_parser = sub.add_parser("list", help="Print the ledger")
    list_parser.set_defaults(func=list_reports)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
