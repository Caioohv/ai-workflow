"""Installer checks using isolated temporary projects and no external dependencies."""

from pathlib import Path
import os
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
            ".claude/agents/orchestrator.md", ".agents/skills/orchestrator/SKILL.md",
            ".agents/skills/todo-planner/SKILL.md",
            ".agents/skills/implementer-auto/SKILL.md",
            "workflow/definition.md", "workflow/project-memory.md",
            "workflow/templates/task.md", "workflow/tasks/to-review",
            "workflow/steps/done", "workflow/todos", "workflow/decisions",
            "workflow/templates/adr.md", ".claude/skills/state-management/SKILL.md",
            ".agents/skills/state-management/SKILL.md", ".git",
            "workflow/verify.sh", "workflow/.ai-workflow-manifest",
        ):
            self.assertTrue((self.target / name).exists(), name)
        for name in ("AGENTS.md", "CLAUDE.md", "GEMINI.md"):
            self.assertEqual((self.target / name).read_text(), (REPO / name).read_text(), name)
        self.assertTrue(os.access(self.target / "workflow/verify.sh", os.X_OK))

    def test_fresh_install_appends_block_to_existing_instructions(self):
        self.target.mkdir()
        for name in ("CLAUDE.md", "GEMINI.md"):
            (self.target / name).write_text("# Mine\nKeep this.\n")
        self.run_setup()
        for name in ("CLAUDE.md", "GEMINI.md"):
            self.assertEqual((self.target / name).read_text(), "# Mine\nKeep this.\n" + (REPO / name).read_text())

    def test_update_keeps_project_customizations(self):
        self.run_setup()
        custom = {
            ".claude/agents/my-agent.md": "my agent\n",
            ".claude/skills/my-skill/SKILL.md": "my skill\n",
            ".agents/skills/my-skill/SKILL.md": "my shared skill\n",
            ".agents/rules/team.md": "team rules\n",
            ".claude/settings.json": '{"permissions": {"allow": ["Bash(npm run *)"]}}\n',
            "workflow/templates/my-template.md": "mine\n",
        }
        for name, content in custom.items():
            path = self.target / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        for name in ("CLAUDE.md", "GEMINI.md"):
            path = self.target / name
            path.write_text("Local notes\n" + path.read_text().replace("# ", "# Old ", 1))
        (self.target / ".claude/agents/executor.md").write_text("stale")
        self.run_setup("--update")
        for name, content in custom.items():
            self.assertEqual((self.target / name).read_text(), content, name)
        for name in ("CLAUDE.md", "GEMINI.md"):
            text = (self.target / name).read_text()
            self.assertEqual(text, "Local notes\n" + (REPO / name).read_text(), name)
            self.assertEqual(text.count(BEGIN), 1)
        self.assertEqual(
            (self.target / ".claude/agents/executor.md").read_text(),
            (REPO / ".claude/agents/executor.md").read_text(),
        )

    def test_update_removes_only_files_dropped_from_framework(self):
        self.run_setup()
        manifest = self.target / "workflow/.ai-workflow-manifest"
        outside = Path(self.workspace.name) / "outside.txt"
        dropped = [".claude/agents/retired.md", ".agents/skills/retired/SKILL.md"]
        unsafe = ["../outside.txt", "workflow/definition.md"]
        for name in dropped:
            (self.target / name).parent.mkdir(parents=True, exist_ok=True)
            (self.target / name).write_text("old framework file")
        outside.write_text("not ours")
        with manifest.open("a") as stream:
            stream.write("\n".join(dropped + unsafe) + "\n")
        self.run_setup("--update")
        for name in dropped:
            self.assertFalse((self.target / name).exists(), name)
        self.assertFalse((self.target / ".agents/skills/retired").exists())
        self.assertEqual(outside.read_text(), "not ours")
        self.assertTrue((self.target / "workflow/definition.md").is_file())
        self.assertNotIn("retired", manifest.read_text())

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
                self.assertTrue((target / "workflow/decisions").is_dir())
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
                self.assertEqual(list(self.target.iterdir()), [agents])

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
