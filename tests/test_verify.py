"""Checks for workflow/verify.sh using a throwaway Node project."""

from pathlib import Path
import json
import os
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("node") and shutil.which("npm"), "needs node and npm")
class VerifyTests(unittest.TestCase):
    def setUp(self):
        workspace = tempfile.TemporaryDirectory(prefix="ai-workflow-verify-")
        self.addCleanup(workspace.cleanup)
        self.project = Path(workspace.name)
        (self.project / "workflow").mkdir()
        shutil.copy2(REPO / "workflow/verify.sh", self.project / "workflow/verify.sh")

    def verify(self, scripts, *args):
        (self.project / "package.json").write_text(json.dumps({"name": "x", "version": "1.0.0", "scripts": scripts}))
        env = {**os.environ, "VERIFY_TAIL": "3"}
        return subprocess.run(
            ["bash", str(self.project / "workflow/verify.sh"), *args],
            capture_output=True, text=True, env=env,
        )

    def test_reports_one_line_per_check_and_only_failure_tails(self):
        result = self.verify({
            "lint": "echo lint-noise",
            "type-check": "echo typed",
            "test": 'echo "Error: no test specified" && exit 1',
            "build": "echo first && echo boom && exit 3",
        })
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertRegex(result.stdout, r"ok   lint")
        self.assertRegex(result.stdout, r"ok   type-check")
        self.assertRegex(result.stdout, r"FAIL build")
        self.assertIn("boom", result.stdout)
        self.assertNotIn("lint-noise", result.stdout)
        self.assertNotIn("test", result.stdout.replace("type-check", ""))

    def test_runs_only_requested_checks(self):
        result = self.verify({"lint": "true", "build": "exit 1"}, "lint")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn("build", result.stdout)

    def test_no_scripts_is_not_a_failure(self):
        result = self.verify({"dev": "true"})
        self.assertEqual(result.returncode, 0)
        self.assertIn("no checks yet", result.stdout)


if __name__ == "__main__":
    unittest.main()
