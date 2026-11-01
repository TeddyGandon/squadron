#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def main():
    result_path = Path(sys.argv[1])
    response = result_path.read_text()
    decoder = json.JSONDecoder()

    for offset, character in enumerate(response):
        if character != "{":
            continue
        try:
            report, _ = decoder.raw_decode(response[offset:])
        except json.JSONDecodeError:
            continue
        if (
            isinstance(report, dict)
            and isinstance(report.get("validated"), bool)
            and isinstance(report.get("summary"), str)
            and isinstance(report.get("findings"), list)
        ):
            result_path.write_text(json.dumps(report))
            return

    print("::error::Reviewer response did not contain a valid JSON report.", file=sys.stderr)
    raise SystemExit(1)


if __name__ == "__main__":
    main()