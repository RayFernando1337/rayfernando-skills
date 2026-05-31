#!/usr/bin/env python3
"""Validate skill metadata against Codex-compatible limits.

Codex loads every skill's name and description into its initial skills
metadata block before it progressively reads the full SKILL.md. The skill
frontmatter description therefore needs to be concise, and Codex rejects
descriptions longer than 1024 characters.

This validator intentionally uses only the Python standard library so release
CI can run it without installing dependencies. It supports the simple
frontmatter shapes used in this repository, including folded and literal block
scalars for `description`.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


MAX_SKILL_NAME_LENGTH = 64
MAX_DESCRIPTION_LENGTH = 1024
RECOMMENDED_DESCRIPTION_LENGTH = 350
ALLOWED_FRONTMATTER_KEYS = {
    "name",
    "description",
    "license",
    "allowed-tools",
    "metadata",
}
EXCLUDED_DIRS = {
    ".git",
    ".hg",
    ".svn",
    ".tox",
    ".venv",
    "__pycache__",
    "node_modules",
    "dist",
    "build",
    "cache",
}


@dataclass
class CheckResult:
    label: str
    description_length: int | None
    errors: list[str]
    warnings: list[str]


def iter_skill_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("SKILL.md"):
        if any(part in EXCLUDED_DIRS for part in path.parts):
            continue
        yield path


def strip_scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        value = value[1:-1]
    return value.strip()


def block_indent(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def parse_block_scalar(lines: list[str], start: int, parent_indent: int, style: str) -> tuple[str, int]:
    block_lines: list[str] = []
    index = start
    content_indent: int | None = None

    while index < len(lines):
        line = lines[index]
        if line.strip() == "":
            block_lines.append("")
            index += 1
            continue

        indent = block_indent(line)
        if indent <= parent_indent:
            break

        if content_indent is None:
            content_indent = indent

        block_lines.append(line[content_indent:])
        index += 1

    chomp_strip = style.endswith("-")
    if style.startswith("|"):
        value = "\n".join(block_lines)
    else:
        paragraphs: list[str] = []
        current: list[str] = []
        for line in block_lines:
            stripped = line.strip()
            if stripped == "":
                if current:
                    paragraphs.append(" ".join(current))
                    current = []
                paragraphs.append("")
            else:
                current.append(stripped)
        if current:
            paragraphs.append(" ".join(current))
        value = "\n".join(paragraphs).strip()

    if not chomp_strip:
        value += "\n"
    return value, index


def parse_simple_frontmatter(frontmatter_text: str) -> dict[str, str]:
    """Parse the frontmatter subset used by this repo.

    This is not a general YAML parser. It handles top-level `key: value`
    strings and top-level block scalars (`key: >-` / `key: |-`). Complex YAML
    should stay out of SKILL.md metadata; if it appears, this function still
    detects the key names so unexpected keys can be reported.
    """

    parsed: dict[str, str] = {}
    lines = frontmatter_text.splitlines()
    index = 0

    while index < len(lines):
        line = lines[index]
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            index += 1
            continue
        if line.startswith(" ") or line.startswith("\t"):
            index += 1
            continue

        match = re.match(r"^([A-Za-z0-9_-]+):(?:\s*(.*))?$", line)
        if not match:
            index += 1
            continue

        key, raw_value = match.group(1), (match.group(2) or "")
        value = raw_value.strip()
        if value in {">", ">-", ">+", "|", "|-", "|+"}:
            parsed[key], index = parse_block_scalar(lines, index + 1, block_indent(line), value)
            continue

        parsed[key] = strip_scalar(value)
        index += 1

    return parsed


def extract_frontmatter(content: str) -> tuple[str | None, str | None]:
    if not content.startswith("---\n"):
        return None, "No YAML frontmatter found"

    end = content.find("\n---", 4)
    if end == -1:
        return None, "Invalid frontmatter format: missing closing ---"

    return content[4:end], None


def validate_skill_file(path: Path, root: Path) -> CheckResult:
    rel = path.relative_to(root)
    errors: list[str] = []
    warnings: list[str] = []

    content = path.read_text(encoding="utf-8")
    frontmatter_text, frontmatter_error = extract_frontmatter(content)
    if frontmatter_error:
        return CheckResult(str(rel), None, [frontmatter_error], warnings)

    frontmatter = parse_simple_frontmatter(frontmatter_text or "")
    unexpected_keys = set(frontmatter) - ALLOWED_FRONTMATTER_KEYS
    if unexpected_keys:
        allowed = ", ".join(sorted(ALLOWED_FRONTMATTER_KEYS))
        unexpected = ", ".join(sorted(unexpected_keys))
        errors.append(f"Unexpected frontmatter key(s): {unexpected}. Allowed keys: {allowed}")

    name = frontmatter.get("name", "").strip()
    if not name:
        errors.append("Missing required frontmatter key: name")
    elif not re.match(r"^[a-z0-9-]+$", name):
        errors.append("Skill name must be hyphen-case lowercase letters, digits, and hyphens only")
    elif name.startswith("-") or name.endswith("-") or "--" in name:
        errors.append("Skill name cannot start/end with a hyphen or contain consecutive hyphens")
    elif len(name) > MAX_SKILL_NAME_LENGTH:
        errors.append(
            f"Skill name is {len(name)} characters; maximum is {MAX_SKILL_NAME_LENGTH}"
        )

    description = frontmatter.get("description")
    if description is None or description.strip() == "":
        errors.append("Missing required frontmatter key: description")
        description_length = None
    else:
        description = description.strip()
        description_length = len(description)
        if "<" in description or ">" in description:
            errors.append("Description cannot contain angle brackets (< or >)")
        if description_length > MAX_DESCRIPTION_LENGTH:
            errors.append(
                f"Description is {description_length} characters; maximum is {MAX_DESCRIPTION_LENGTH}"
            )
        elif description_length > RECOMMENDED_DESCRIPTION_LENGTH:
            warnings.append(
                f"Description is {description_length} characters; recommended budget is "
                f"{RECOMMENDED_DESCRIPTION_LENGTH}"
            )

    return CheckResult(str(rel), description_length, errors, warnings)


def validate_json_description(path: Path, label: str, description: object, root: Path) -> CheckResult:
    rel_label = f"{path.relative_to(root)}:{label}"
    errors: list[str] = []
    warnings: list[str] = []

    if not isinstance(description, str):
        return CheckResult(rel_label, None, ["Description must be a string"], warnings)

    description_length = len(description.strip())
    if description_length > MAX_DESCRIPTION_LENGTH:
        errors.append(
            f"Description is {description_length} characters; maximum is {MAX_DESCRIPTION_LENGTH}"
        )
    elif description_length > RECOMMENDED_DESCRIPTION_LENGTH:
        warnings.append(
            f"Description is {description_length} characters; recommended budget is "
            f"{RECOMMENDED_DESCRIPTION_LENGTH}"
        )

    return CheckResult(rel_label, description_length, errors, warnings)


def iter_json_description_checks(root: Path) -> Iterable[CheckResult]:
    marketplace = root / ".claude-plugin" / "marketplace.json"
    if marketplace.exists():
        data = json.loads(marketplace.read_text(encoding="utf-8"))
        for index, plugin in enumerate(data.get("plugins", [])):
            name = plugin.get("name", f"plugin-{index}")
            yield validate_json_description(
                marketplace,
                f"plugins[{index}] {name} description",
                plugin.get("description"),
                root,
            )

    plugins_root = root / "plugins"
    if plugins_root.exists():
        for manifest in sorted(plugins_root.glob("*/.claude-plugin/plugin.json")):
            data = json.loads(manifest.read_text(encoding="utf-8"))
            yield validate_json_description(manifest, "description", data.get("description"), root)


def print_result(result: CheckResult) -> None:
    if result.description_length is None:
        print(f"- {result.label}: description length unavailable")
    else:
        print(f"- {result.label}: description {result.description_length} chars")

    for warning in result.warnings:
        print(f"  warning: {warning}")
    for error in result.errors:
        print(f"  error: {error}")


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    results: list[CheckResult] = []

    print("Validating SKILL.md frontmatter:")
    skill_files = sorted(iter_skill_files(root))
    if not skill_files:
        print("- no SKILL.md files found")
    for skill_file in skill_files:
        result = validate_skill_file(skill_file, root)
        print_result(result)
        results.append(result)

    print("\nValidating plugin and marketplace descriptions:")
    json_results = list(iter_json_description_checks(root))
    if not json_results:
        print("- no plugin or marketplace descriptions found")
    for result in json_results:
        print_result(result)
        results.append(result)

    errors = [error for result in results for error in result.errors]
    if errors:
        print(f"\nMetadata validation failed with {len(errors)} error(s).")
        return 1

    print("\nMetadata validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
