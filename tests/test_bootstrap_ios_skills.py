import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "plugins"
    / "bootstrap-ios"
    / "skills"
    / "bootstrap-ios"
    / "scripts"
    / "bootstrap-ios-skills.sh"
)

# macOS ships bash 3.2; the script must stay compatible with it. /bin/bash is
# bash 3.2 on macOS runners and modern bash elsewhere, so running the script
# through /bin/bash covers the oldest interpreter we support on each platform.
BASH = "/bin/bash"


def expected_skills() -> list:
    """Parse the expected_skills=( ... ) array out of the script so the tests
    never drift from the list the script actually verifies."""
    text = SCRIPT.read_text()
    start = text.index("expected_skills=(")
    end = text.index(")", start)
    body = text[start + len("expected_skills=(") : end]
    names = [
        line.strip()
        for line in body.splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]
    assert names, "expected_skills array parsed empty"
    return names


def run_script(*args, env=None):
    return subprocess.run(
        [BASH, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        env=env,
    )


class DryRunTest(unittest.TestCase):
    def test_dry_run_without_agent_succeeds(self):
        """Regression: empty agent_args array crashed bash 3.2 under set -u."""
        result = run_script("--dry-run")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("unbound variable", result.stderr)
        self.assertIn("DRY RUN: npx skills add", result.stdout)
        self.assertNotIn(" -a ", result.stdout)

    def test_dry_run_with_agent_appends_agent_flag(self):
        result = run_script("--dry-run", "--agent", "cursor")

        self.assertEqual(result.returncode, 0, result.stderr)
        for line in result.stdout.splitlines():
            if line.startswith("DRY RUN: npx skills add"):
                self.assertIn("-a cursor", line)

    def test_dry_run_skips_verification(self):
        result = run_script("--dry-run")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("Verified:", result.stdout)
        self.assertNotIn("SHALLOW INSTALL", result.stderr)


class VerifyInstallTest(unittest.TestCase):
    """Run the script for real against a stubbed npx and a fake HOME."""

    def make_env(self, home: Path) -> dict:
        bin_dir = home / "stub-bin"
        bin_dir.mkdir(parents=True, exist_ok=True)
        npx = bin_dir / "npx"
        npx.write_text("#!/bin/sh\nexit 0\n")
        npx.chmod(npx.stat().st_mode | stat.S_IEXEC)

        env = os.environ.copy()
        env["HOME"] = str(home)
        env["PATH"] = f"{bin_dir}:{env['PATH']}"
        return env

    def write_skill(self, home: Path, name: str, *, complete: bool) -> None:
        skill_dir = home / ".agents" / "skills" / name
        (skill_dir / "references").mkdir(parents=True, exist_ok=True)
        (skill_dir / "SKILL.md").write_text(
            f"---\nname: {name}\n---\n\nConsult `references/core.md` first.\n"
        )
        if complete:
            (skill_dir / "references" / "core.md").write_text("# core\n")

    def write_all_skills(self, home: Path, **overrides) -> None:
        """Write every expected skill complete, except per-name overrides:
        complete=False for shallow, or None to omit the skill entirely."""
        for name in expected_skills():
            mode = overrides.get(name, True)
            if mode is None:
                continue
            self.write_skill(home, name, complete=mode)

    def test_complete_install_passes_verification(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            self.write_all_skills(home)
            env = self.make_env(home)

            result = run_script("--agent", "cursor", env=env)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Verified:", result.stdout)

    def test_shallow_install_fails_verification(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            self.write_all_skills(home, **{"swiftui-pro": False})
            env = self.make_env(home)

            result = run_script("--agent", "cursor", env=env)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("SHALLOW INSTALL", result.stderr)
            self.assertIn("references/core.md", result.stderr)

    def test_missing_skill_fails_verification(self):
        """Regression (cursor[bot] review): a pack the installer never laid
        down must fail verification, not just warn."""
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            self.write_all_skills(home, **{"swiftui-pro": None})
            env = self.make_env(home)

            result = run_script("--agent", "cursor", env=env)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("NOT INSTALLED: swiftui-pro", result.stderr)
            self.assertNotIn("Verified:", result.stdout)

    def test_skip_verify_opts_out(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            self.write_all_skills(home, **{"swiftui-pro": False})
            env = self.make_env(home)

            result = run_script("--agent", "cursor", "--skip-verify", env=env)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn("SHALLOW INSTALL", result.stderr)


if __name__ == "__main__":
    unittest.main()
