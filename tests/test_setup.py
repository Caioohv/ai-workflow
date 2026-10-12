"""Installer checks using isolated temporary projects and no external dependencies."""

from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
BEGIN = "<!-- ai-workflow:begin -->"
END = "<!-- ai-workflow:end -->"


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory(prefix="ai-workflow-test-")
        self.addCleanup(self.workspace.cleanup)
        self.target = Path(self.workspace.name) / "project with spaces"

    def run_setup(self, *args, success=True, target=None):
        result = subprocess.run(
            ["bash", str(REPO / "setup.sh"), str(target or self.target), *args],
            capture_output=True,
            text=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_fresh_install_supports_all_harnesses(self):
        self.run_setup()
        for name in (
            "AGENTS.md", "CLAUDE.md", "GEMINI.md", ".claude/settings.json",
            ".claude/agents/implementer.md", ".agents/rules/rules.md",
            ".agents/skills/todo-planner/SKILL.md",
            ".agents/skills/implementer-auto/SKILL.md",
            "workflow/definition.md", "workflow/project-memory.md",
            "workflow/templates/task.md", "workflow/tasks/to-review",
            "workflow/steps/done", "workflow/todos", ".git",
        ):
            self.assertTrue((self.target / name).exists(), name)
        self.assertEqual((self.target / "AGENTS.md").read_text(), (REPO / "AGENTS.md").read_text())

    def test_existing_project_rules_survive_setup_and_update(self):
        self.target.mkdir()
        agents = self.target / "AGENTS.md"
        agents.write_text("# Project rules\nUse our conventions.\n")
        self.run_setup()
        with agents.open("a") as stream:
            stream.write("\n# More local rules\nKeep these too.\n")
        self.run_setup("--update")
        first_update = agents.read_text()
        self.assertIn("# Project rules\nUse our conventions.\n", first_update)
        self.assertIn("# More local rules\nKeep these too.\n", first_update)
        self.assertEqual(first_update.count(BEGIN), 1)
        self.assertEqual(first_update.count(END), 1)
        self.run_setup("--update")
        self.assertEqual(agents.read_text(), first_update)

    def test_update_refreshes_managed_block_and_preserves_workflow_state(self):
        self.run_setup()
        agents = self.target / "AGENTS.md"
        agents.write_text(f"Local rules\n{BEGIN}\nOld instructions\n{END}\nOther rules\n")
        preserved = {
            "workflow/definition.md": "Custom project definition\n",
            "workflow/project-memory.md": "Known gotchas\n",
            "workflow/tasks/todo/01-task.md": "Pending task\n",
            "workflow/steps/in-progress/01-step.md": "In-progress step\n",
            "workflow/design.md": "Custom tokens\n",
        }
        for name, content in preserved.items():
            (self.target / name).write_text(content)
        (self.target / "workflow/templates/task.md").write_text("Old template")
        self.run_setup("--update")
        for name, content in preserved.items():
            self.assertEqual((self.target / name).read_text(), content, name)
        self.assertEqual(agents.read_text(), "Local rules\nOther rules\n" + (REPO / "AGENTS.md").read_text())
        self.assertEqual((self.target / "workflow/templates/task.md").read_text(), (REPO / "workflow/templates/task.md").read_text())

    def test_legacy_installations_gain_codex_support(self):
        for harness in (".claude", ".agents"):
            with self.subTest(harness=harness):
                target = Path(self.workspace.name) / harness
                (target / harness).mkdir(parents=True)
                (target / "workflow").mkdir()
                (target / "workflow/definition.md").write_text("Existing definition")
                self.run_setup("--update", target=target)
                self.assertTrue((target / "AGENTS.md").is_file())
                self.assertTrue((target / ".agents/skills/todo-planner/SKILL.md").is_file())
                self.assertEqual((target / "workflow/definition.md").read_text(), "Existing definition")

    def test_invalid_markers_do_not_destroy_local_instructions(self):
        self.target.mkdir()
        agents = self.target / "AGENTS.md"
        for content in (
            f"Local rules\n{BEGIN}\nUnclosed instructions\n",
            f"Local rules\n{END}\n",
            f"{BEGIN}\n{END}\n{BEGIN}\n{END}\n",
        ):
            with self.subTest(content=content):
                agents.write_text(content)
                self.run_setup(success=False)
                self.assertEqual(agents.read_text(), content)
                self.assertEqual(list(self.target.glob(".ai-workflow-agents.*")), [])

    def test_self_update_is_rejected_before_mutation(self):
        before = (REPO / "setup.sh").read_bytes()
        self.run_setup("--update", success=False, target=REPO)
        self.assertEqual((REPO / "setup.sh").read_bytes(), before)
        self.assertTrue((REPO / ".agents/skills/implementer/SKILL.md").is_file())

    def test_update_rejects_uninstalled_project(self):
        self.target.mkdir()
        self.run_setup("--update", success=False)
        self.assertEqual(list(self.target.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
