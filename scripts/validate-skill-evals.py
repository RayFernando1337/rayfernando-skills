#!/usr/bin/env python3
"""Validate skill eval definitions (evals/evals.json) shipped with skills.

Skills in this repository may ship behavior evals following the Anthropic
skill-creator convention: an `evals/evals.json` inside the skill directory
with a `skill_name` and a list of evals, each carrying an `id`, a `prompt`,
an `expected_output`, optional fixture `files` (paths relative to the skill
root), and a non-empty list of objectively gradeable `expectations`.

This validator intentionally uses only the Python standard library so release
CI can run it without installing dependencies. Skills without an evals/
directory are skipped; a skill that ships evals must ship well-formed ones.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


REQUIRED_EVAL_KEYS = {"id", "prompt", "expected_output", "expectations"}


@dataclass
class EvalCheckResult:
    label: str
    eval_count: int
    errors: list[str] = field(default_factory=list)


def iter_eval_files(root: Path) -> Iterable[tuple[Path, Path]]:
    plugins_root = root / "plugins"
    if not plugins_root.exists():
        return
    for skill_dir in sorted(plugins_root.glob("*/skills/*")):
        evals_file = skill_dir / "evals" / "evals.json"
        if evals_file.exists():
            yield skill_dir, evals_file


def validate_eval_file(skill_dir: Path, evals_file: Path, root: Path) -> EvalCheckResult:
    label = str(evals_file.relative_to(root))
    errors: list[str] = []

    try:
        data = json.loads(evals_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return EvalCheckResult(label, 0, [f"Invalid JSON: {exc}"])

    if not isinstance(data, dict):
        return EvalCheckResult(label, 0, ["Top level must be a JSON object"])

    skill_name = data.get("skill_name")
    if skill_name != skill_dir.name:
        errors.append(
            f"skill_name must match the skill directory name '{skill_dir.name}' "
            f"(found: {skill_name!r})"
        )

    evals = data.get("evals")
    if not isinstance(evals, list) or not evals:
        errors.append("evals must be a non-empty list")
        return EvalCheckResult(label, 0, errors)

    seen_ids: set[object] = set()
    for index, entry in enumerate(evals):
        prefix = f"evals[{index}]"
        if not isinstance(entry, dict):
            errors.append(f"{prefix}: must be an object")
            continue

        missing = REQUIRED_EVAL_KEYS - set(entry)
        if missing:
            errors.append(f"{prefix}: missing required key(s): {', '.join(sorted(missing))}")

        eval_id = entry.get("id")
        if not isinstance(eval_id, int):
            errors.append(f"{prefix}: id must be an integer (found: {eval_id!r})")
        elif eval_id in seen_ids:
            errors.append(f"{prefix}: duplicate id {eval_id}")
        else:
            seen_ids.add(eval_id)

        for key in ("prompt", "expected_output"):
            value = entry.get(key)
            if key in entry and (not isinstance(value, str) or not value.strip()):
                errors.append(f"{prefix}: {key} must be a non-empty string")

        expectations = entry.get("expectations")
        if "expectations" in entry:
            if not isinstance(expectations, list) or not expectations:
                errors.append(f"{prefix}: expectations must be a non-empty list")
            else:
                for exp_index, expectation in enumerate(expectations):
                    if not isinstance(expectation, str) or not expectation.strip():
                        errors.append(
                            f"{prefix}: expectations[{exp_index}] must be a non-empty string"
                        )

        files = entry.get("files", [])
        if not isinstance(files, list):
            errors.append(f"{prefix}: files must be a list of skill-relative paths")
            files = []
        for file_index, file_path in enumerate(files):
            if not isinstance(file_path, str) or not file_path.strip():
                errors.append(f"{prefix}: files[{file_index}] must be a non-empty string")
                continue
            candidate = Path(file_path)
            if candidate.is_absolute() or ".." in candidate.parts:
                errors.append(
                    f"{prefix}: files[{file_index}] must be a relative path inside the "
                    f"skill directory (found: {file_path!r})"
                )
                continue
            if not (skill_dir / candidate).exists():
                errors.append(
                    f"{prefix}: files[{file_index}] does not exist: {file_path!r}"
                )

    return EvalCheckResult(label, len(evals), errors)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    results: list[EvalCheckResult] = []

    print("Validating skill eval definitions:")
    eval_files = list(iter_eval_files(root))
    if not eval_files:
        print("- no evals/evals.json files found")
    for skill_dir, evals_file in eval_files:
        result = validate_eval_file(skill_dir, evals_file, root)
        print(f"- {result.label}: {result.eval_count} eval(s)")
        for error in result.errors:
            print(f"  error: {error}")
        results.append(result)

    errors = [error for result in results for error in result.errors]
    if errors:
        print(f"\nEval validation failed with {len(errors)} error(s).")
        return 1

    print("\nEval validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
