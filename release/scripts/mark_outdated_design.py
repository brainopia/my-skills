#!/usr/bin/env python3
"""Insert or refresh an OUTDATED section in a design document."""

from __future__ import annotations

import argparse
from pathlib import Path


def normalize_item(text: str) -> str:
    stripped = text.strip()
    if stripped.startswith("- "):
        return stripped[2:].strip()
    return stripped


def build_section(items: list[str]) -> list[str]:
    section = ["## OUTDATED", ""]
    for item in items:
        section.append(f"- {normalize_item(item)}")
    section.append("")
    return section


def replace_existing(lines: list[str], section: list[str]) -> list[str] | None:
    start = None
    for index, line in enumerate(lines):
        if line.strip() in {"## OUTDATED", "# OUTDATED", "OUTDATED:"}:
            start = index
            break
    if start is None:
        return None

    end = len(lines)
    for index in range(start + 1, len(lines)):
        stripped = lines[index].strip()
        if stripped.startswith("## ") or stripped.startswith("# "):
            end = index
            break
    return lines[:start] + section + lines[end:]


def insert_near_top(lines: list[str], section: list[str]) -> list[str]:
    first_non_empty = next((i for i, line in enumerate(lines) if line.strip()), None)
    if first_non_empty is not None and lines[first_non_empty].startswith("# "):
        head = lines[: first_non_empty + 1]
        tail = lines[first_non_empty + 1 :]
        while tail and not tail[0].strip():
            tail = tail[1:]
        return head + [""] + section + tail
    while lines and not lines[0].strip():
        lines = lines[1:]
    return section + lines


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Insert or refresh an OUTDATED section near the top of a markdown design document."
    )
    parser.add_argument("path", help="Path to the design markdown file to update.")
    parser.add_argument(
        "--item",
        action="append",
        required=True,
        help="Bullet item describing one outdated point. Repeat for multiple items.",
    )
    args = parser.parse_args()

    target = Path(args.path)
    if not target.is_file():
        parser.error(f"File not found: {target}")

    original_text = target.read_text()
    trailing_newline = original_text.endswith("\n")
    lines = original_text.splitlines()
    section = build_section(args.item)

    updated_lines = replace_existing(lines, section)
    if updated_lines is None:
        updated_lines = insert_near_top(lines, section)

    updated_text = "\n".join(updated_lines)
    if trailing_newline or not updated_text.endswith("\n"):
        updated_text += "\n"

    target.write_text(updated_text)
    print(f"Updated OUTDATED section in {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
