#!/usr/bin/env python3
"""Turn the requirements check's Copilot output into an issue comment and a verdict.

Usage: extract-requirements-report.py <copilot-output-file> <comment-file>

Finds the first JSON object with a boolean "ready" field in the output, writes the
missing-requirements comment to <comment-file>, and writes ready=true|false to $GITHUB_OUTPUT.
A "ready": false verdict without any listed requirement is treated as ready, so the coder is
never blocked without an actionable question. Missing or malformed optional fields are tolerated.
"""
import json
import os
import sys
from pathlib import Path

HEADER = "## Squadron requirements check"


def find_report(text):
    decoder = json.JSONDecoder()
    for offset, character in enumerate(text):
        if character != "{":
            continue
        try:
            report, _ = decoder.raw_decode(text, offset)
        except json.JSONDecodeError:
            continue
        if isinstance(report, dict) and isinstance(report.get("ready"), bool):
            return report
    return None


def format_requirement(index, requirement):
    if not isinstance(requirement, dict):
        return f"{index}. {requirement}"
    topic = str(requirement.get("topic") or "").strip()
    question = str(requirement.get("question") or "").strip()
    reason = str(requirement.get("reason") or "").strip()
    line = f"{index}. **{topic}:** {question}" if topic else f"{index}. {question}"
    if reason:
        line += f"\n   _Why:_ {reason}"
    return line


def main():
    output_path, comment_path = Path(sys.argv[1]), Path(sys.argv[2])
    report = find_report(output_path.read_text(encoding="utf-8", errors="replace"))
    if report is None:
        print("::error::Requirements check response did not contain a valid JSON report.", file=sys.stderr)
        raise SystemExit(1)

    requirements = report.get("missing_requirements")
    requirements = [r for r in requirements if r] if isinstance(requirements, list) else []
    ready = report["ready"] or not requirements

    if not ready:
        lines = [
            HEADER,
            "",
            "The coder did not start: the issue is missing requirements needed to implement and test it without guessing.",
            "",
            str(report.get("summary") or "").strip(),
            "",
            "### Missing requirements",
            "\n".join(format_requirement(i, r) for i, r in enumerate(requirements, start=1)),
            "",
            "### Next step",
            "Answer these points **in the issue title or body** (the coder and tester only read those, not comments), "
            "then remove and re-apply `status:todo` to restart the coder.",
        ]
        comment_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as handle:
            handle.write(f"ready={str(ready).lower()}\n")


if __name__ == "__main__":
    main()
