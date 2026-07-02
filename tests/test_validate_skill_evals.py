import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


def load_validator():
    script = Path(__file__).resolve().parents[1] / "scripts" / "validate-skill-evals.py"
    spec = importlib.util.spec_from_file_location("validate_skill_evals", script)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def write_skill(root: Path, skill_name: str, evals: dict) -> Path:
    skill_dir = root / "plugins" / skill_name / "skills" / skill_name
    (skill_dir / "evals").mkdir(parents=True)
    (skill_dir / "evals" / "evals.json").write_text(json.dumps(evals), encoding="utf-8")
    return skill_dir


def valid_evals(skill_name: str) -> dict:
    return {
        "skill_name": skill_name,
        "evals": [
            {
                "id": 1,
                "prompt": "Do the thing",
                "expected_output": "The thing is done",
                "files": ["evals/files/data.csv"],
                "expectations": ["The output includes the count"],
            }
        ],
    }


class ValidateSkillEvalsTest(unittest.TestCase):
    def test_valid_evals_pass(self):
        validator = load_validator()
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill_dir = write_skill(root, "demo-skill", valid_evals("demo-skill"))
            (skill_dir / "evals" / "files").mkdir()
            (skill_dir / "evals" / "files" / "data.csv").write_text("a,b\n1,2\n")

            result = validator.validate_eval_file(
                skill_dir, skill_dir / "evals" / "evals.json", root
            )

            self.assertEqual(result.errors, [])
            self.assertEqual(result.eval_count, 1)

    def test_missing_fixture_file_is_an_error(self):
        validator = load_validator()
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill_dir = write_skill(root, "demo-skill", valid_evals("demo-skill"))

            result = validator.validate_eval_file(
                skill_dir, skill_dir / "evals" / "evals.json", root
            )

            self.assertTrue(any("does not exist" in error for error in result.errors))

    def test_duplicate_ids_and_wrong_skill_name_are_errors(self):
        validator = load_validator()
        evals = {
            "skill_name": "other-skill",
            "evals": [
                {"id": 1, "prompt": "p", "expected_output": "o", "expectations": ["e"]},
                {"id": 1, "prompt": "p2", "expected_output": "o2", "expectations": ["e2"]},
            ],
        }
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill_dir = write_skill(root, "demo-skill", evals)

            result = validator.validate_eval_file(
                skill_dir, skill_dir / "evals" / "evals.json", root
            )

            self.assertTrue(any("duplicate id 1" in error for error in result.errors))
            self.assertTrue(any("skill_name must match" in error for error in result.errors))

    def test_empty_expectations_are_an_error(self):
        validator = load_validator()
        evals = {
            "skill_name": "demo-skill",
            "evals": [
                {"id": 1, "prompt": "p", "expected_output": "o", "expectations": []},
            ],
        }
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill_dir = write_skill(root, "demo-skill", evals)

            result = validator.validate_eval_file(
                skill_dir, skill_dir / "evals" / "evals.json", root
            )

            self.assertTrue(
                any("expectations must be a non-empty list" in error for error in result.errors)
            )

    def test_escaping_paths_are_rejected(self):
        validator = load_validator()
        evals = valid_evals("demo-skill")
        evals["evals"][0]["files"] = ["../../../etc/passwd"]
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill_dir = write_skill(root, "demo-skill", evals)

            result = validator.validate_eval_file(
                skill_dir, skill_dir / "evals" / "evals.json", root
            )

            self.assertTrue(
                any("relative path inside the skill directory" in error for error in result.errors)
            )
