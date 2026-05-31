import importlib.util
import sys
import unittest
from pathlib import Path


def load_validator():
    script = Path(__file__).resolve().parents[1] / "scripts" / "validate-skill-metadata.py"
    spec = importlib.util.spec_from_file_location("validate_skill_metadata", script)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ValidateSkillMetadataTest(unittest.TestCase):
    def test_literal_block_scalar_strips_detected_content_indent(self):
        validator = load_validator()
        frontmatter = "description: |-\n    line one\n      indented child\n"

        parsed = validator.parse_simple_frontmatter(frontmatter)

        self.assertEqual(parsed["description"], "line one\n  indented child")

    def test_folded_block_scalar_still_matches_skill_description_shape(self):
        validator = load_validator()
        frontmatter = (
            "description: >-\n"
            "  Runs real-user QA, manual test plans, UX bug hunts, build sign-off,\n"
            "  bug filing, and bug triage for web or iOS/iPadOS apps.\n"
        )

        parsed = validator.parse_simple_frontmatter(frontmatter)

        self.assertEqual(
            parsed["description"],
            "Runs real-user QA, manual test plans, UX bug hunts, build sign-off, "
            "bug filing, and bug triage for web or iOS/iPadOS apps.",
        )
