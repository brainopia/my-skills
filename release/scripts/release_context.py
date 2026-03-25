#!/usr/bin/env python3
"""Summarize release context for the current git repository."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def run(cmd: list[str], cwd: Path, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, capture_output=True, check=check)


def git_output(repo_root: Path, *args: str, check: bool = True) -> str:
    result = run(["git", *args], cwd=repo_root, check=check)
    return result.stdout.strip()


def git_lines(repo_root: Path, *args: str, check: bool = True) -> list[str]:
    output = git_output(repo_root, *args, check=check)
    return [line for line in output.splitlines() if line.strip()]


def parse_status(repo_root: Path) -> list[dict[str, str]]:
    result = run(["git", "status", "--porcelain=v1", "--untracked-files=all"], cwd=repo_root)
    entries: list[dict[str, str]] = []
    for raw_line in result.stdout.splitlines():
        if not raw_line:
            continue
        status = raw_line[:2]
        path_text = raw_line[3:] if len(raw_line) > 3 else ""
        entries.append({"status": status, "path": path_text})
    return entries


def path_exists_in_ref(repo_root: Path, ref: str, relative_path: str) -> bool:
    result = run(["git", "cat-file", "-e", f"{ref}:{relative_path}"], cwd=repo_root, check=False)
    return result.returncode == 0


def gather_docs(repo_root: Path, upstream: str) -> dict[str, object]:
    editable: list[str] = []
    protected_designs: list[str] = []
    protected_plans: list[str] = []
    missing_root_docs: list[str] = []

    for root_doc in ["AGENTS.md", "README.md"]:
        if (repo_root / root_doc).is_file():
            editable.append(root_doc)
        else:
            missing_root_docs.append(root_doc)

    docs_dir = repo_root / "docs"
    if docs_dir.is_dir():
        for path in sorted(p for p in docs_dir.rglob("*") if p.is_file()):
            rel_path = path.relative_to(repo_root).as_posix()
            if rel_path.startswith("docs/plans/") and rel_path.endswith("_design.md") and path_exists_in_ref(repo_root, upstream, rel_path):
                protected_designs.append(rel_path)
            elif rel_path.startswith("docs/plans/") and rel_path.endswith("_plan.md") and path_exists_in_ref(repo_root, upstream, rel_path):
                protected_plans.append(rel_path)
            else:
                editable.append(rel_path)

    return {
        "editable_docs": editable,
        "protected_designs": protected_designs,
        "protected_plans": protected_plans,
        "missing_root_docs": missing_root_docs,
    }


def gather_package(repo_root: Path) -> dict[str, object] | None:
    package_path = repo_root / "package.json"
    if not package_path.is_file():
        return None

    data = json.loads(package_path.read_text())
    return {
        "path": "package.json",
        "name": data.get("name"),
        "version": data.get("version"),
        "has_publish_config": "publishConfig" in data,
    }


def make_context(repo_root: Path) -> dict[str, object]:
    branch = git_output(repo_root, "rev-parse", "--abbrev-ref", "HEAD")
    upstream_result = run(["git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"], cwd=repo_root, check=False)
    if upstream_result.returncode != 0:
        stderr = upstream_result.stderr.strip() or "No upstream configured for the current branch."
        raise RuntimeError(stderr)
    upstream = upstream_result.stdout.strip()

    committed_range = f"{upstream}..HEAD"
    docs = gather_docs(repo_root, upstream)
    package = gather_package(repo_root)

    return {
        "repo_root": repo_root.as_posix(),
        "branch": branch,
        "upstream": upstream,
        "committed_range": committed_range,
        "committed_files": git_lines(repo_root, "diff", "--name-only", committed_range),
        "recent_commits": git_lines(repo_root, "log", "--oneline", committed_range),
        "working_tree": parse_status(repo_root),
        "docs": docs,
        "package": package,
    }


def print_human(context: dict[str, object]) -> None:
    print(f"Repository root: {context['repo_root']}")
    print(f"Current branch: {context['branch']}")
    print(f"Upstream branch: {context['upstream']}")
    print(f"Committed range: {context['committed_range']}")
    print()

    print("Committed files since upstream:")
    committed_files = context["committed_files"]
    if committed_files:
        for path in committed_files:
            print(f"  - {path}")
    else:
        print("  - (none)")
    print()

    print("Recent unpushed commits:")
    recent_commits = context["recent_commits"]
    if recent_commits:
        for line in recent_commits:
            print(f"  - {line}")
    else:
        print("  - (none)")
    print()

    print("Working-tree entries:")
    working_tree = context["working_tree"]
    if working_tree:
        for entry in working_tree:
            print(f"  - {entry['status']} {entry['path']}")
    else:
        print("  - (clean)")
    print()

    docs = context["docs"]
    print("Editable documentation candidates:")
    editable_docs = docs["editable_docs"]
    if editable_docs:
        for path in editable_docs:
            print(f"  - {path}")
    else:
        print("  - (none)")
    print()

    print("Protected pushed design docs:")
    protected_designs = docs["protected_designs"]
    if protected_designs:
        for path in protected_designs:
            print(f"  - {path}")
    else:
        print("  - (none)")
    print()

    print("Protected pushed plan docs:")
    protected_plans = docs["protected_plans"]
    if protected_plans:
        for path in protected_plans:
            print(f"  - {path}")
    else:
        print("  - (none)")
    print()

    missing_root_docs = docs["missing_root_docs"]
    if missing_root_docs:
        print("Missing root docs:")
        for path in missing_root_docs:
            print(f"  - {path}")
        print()

    package = context["package"]
    if package:
        print("Package metadata:")
        print(f"  - path: {package['path']}")
        print(f"  - name: {package['name']}")
        print(f"  - version: {package['version']}")
        print(f"  - publishConfig: {'yes' if package['has_publish_config'] else 'no'}")
    else:
        print("Package metadata:")
        print("  - (no package.json at repository root)")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize release context for the current repository: upstream range, "
            "committed and working-tree files, documentation candidates, protected plan/design docs, "
            "and package metadata."
        )
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of human-readable text.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        repo_root = Path(git_output(Path.cwd(), "rev-parse", "--show-toplevel"))
        context = make_context(repo_root)
    except subprocess.CalledProcessError as exc:
        message = exc.stderr.strip() or exc.stdout.strip() or str(exc)
        print(f"error: {message}", file=sys.stderr)
        return exc.returncode or 1
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(context, indent=2, ensure_ascii=False))
    else:
        print_human(context)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
