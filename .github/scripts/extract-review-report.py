#!/usr/bin/env python3
"""Turn the reviewer's Copilot output into a PR comment and a verdict.

Usage: extract-review-report.py <copilot-output-file> <comment-file>

Finds the first JSON object with a boolean "validated" field in the output, writes the
review comment to <comment-file>, and writes validated=true|false to $GITHUB_OUTPUT.
Missing or malformed optional fields are tolerated so a usable verdict is never lost.
"""
import json
import os
import sys
from pathlib import Path

HEADER = "## Squadron automated review"


def find_report(text):
    decoder = json.JSONDecoder()
    for offset, character in enumerate(text):
        if character != "{":
            continue
        try:
            report, _ = decoder.raw_decode(text, offset)
        except json.JSONDecodeError:
            continue
        if isinstance(report, dict) and isinstance(report.get("validated"), bool):
            return report
    return None


def format_finding(finding):
    if not isinstance(finding, dict):
        return f"- {finding}"
    severity = finding.get("severity") or "note"
    location = str(finding.get("file") or "")
    if location and finding.get("line") not in (None, ""):
        location += f":{finding['line']}"
    message = finding.get("message") or ""
    return f"- [{severity}] {location + ': ' if location else ''}{message}"


def main():
    output_path, comment_path = Path(sys.argv[1]), Path(sys.argv[2])
    report = find_report(output_path.read_text(encoding="utf-8", errors="replace"))
    if report is None:
        print("::error::Reviewer response did not contain a valid JSON report.", file=sys.stderr)
        raise SystemExit(1)

    validated = report["validated"]
    findings = report.get("findings")
    findings = findings if isinstance(findings, list) else []
    lines = [
        HEADER,
        "",
        f"**Validated:** {str(validated).lower()}",
        "",
        str(report.get("summary") or ""),
        "",
        "### Findings",
        "\n".join(map(format_finding, findings)) if findings else "No findings.",
    ]
    comment_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as handle:
            handle.write(f"validated={str(validated).lower()}\n")


if __name__ == "__main__":
    main()
