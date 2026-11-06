"""Guards for skill metadata size and harness parity (token economy)."""

from pathlib import Path
import re
import unittest


REPO = Path(__file__).resolve().parents[1]
CLAUDE_SKILLS = REPO / ".claude/skills"
CLAUDE_AGENTS = REPO / ".claude/agents"
SHARED_SKILLS = REPO / ".agents/skills"
MAX_DESCRIPTION = 350
MAX_ALWAYS_LOADED = 4000
# Pipeline agents whose shared skill differs on purpose (invocation prefix, delegation).
HARNESS_SPECIFIC = {"executor-auto", "implementer-auto", "orchestrator", "todo-planner"}
CLAUDE_ONLY = {"security-scan"}
SKILLS_GUIDE = REPO / "workflow/templates/skills-guide.md"
NOT_PLANNED = {"commit-pr-conventions"}  # used by whoever commits, never chosen per step or task


def frontmatter(path):
    text = path.read_text()
    match = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not match:
        raise AssertionError(f"{path} has no frontmatter")
    fields, current = {}, None
    for line in match.group(1).splitlines():
        key = re.match(r"^([\w-]+):\s*(.*)$", line)
        if key:
            current = key.group(1)
            value = key.group(2)
            fields[current] = "" if value in (">-", ">", "|") else value
        elif current:
            fields[current] = (fields[current] + " " + line.strip()).strip()
    return fields


def body(path):
    return re.sub(r"\A---\n.*?\n---\n", "", path.read_text(), count=1, flags=re.S)


class SkillTests(unittest.TestCase):
    def test_technical_skills_are_mirrored(self):
        for skill in sorted(CLAUDE_SKILLS.iterdir()):
            shared = SHARED_SKILLS / skill.name / "SKILL.md"
            self.assertTrue(shared.is_file(), skill.name)
            self.assertEqual((skill / "SKILL.md").read_text(), shared.read_text(), skill.name)

    def test_names_match_folders_and_descriptions_are_short(self):
        for path in sorted(SHARED_SKILLS.glob("*/SKILL.md")):
            fields = frontmatter(path)
            with self.subTest(skill=path.parent.name):
                self.assertEqual(fields.get("name"), path.parent.name)
                description = fields.get("description", "")
                self.assertTrue(description)
                self.assertLessEqual(len(description), MAX_DESCRIPTION)

    def test_pipeline_agents_match_shared_skills(self):
        for agent in sorted(CLAUDE_AGENTS.glob("*.md")):
            name = agent.stem
            with self.subTest(agent=name):
                self.assertLessEqual(len(frontmatter(agent).get("description", "")), MAX_DESCRIPTION)
                if name in CLAUDE_ONLY:
                    continue
                shared = SHARED_SKILLS / name / "SKILL.md"
                self.assertTrue(shared.is_file(), name)
                if name not in HARNESS_SPECIFIC:
                    self.assertEqual(body(agent), body(shared), name)

    def test_skills_guide_names_existing_skills(self):
        table = SKILLS_GUIDE.read_text().split("## By kind of change", 1)[1]
        named = set(re.findall(r"`([a-z0-9-]+)`", table))
        self.assertTrue(named)
        for name in sorted(named):
            with self.subTest(skill=name):
                self.assertTrue((CLAUDE_SKILLS / name / "SKILL.md").is_file())
                self.assertTrue((SHARED_SKILLS / name / "SKILL.md").is_file())
        covered = {path.name for path in CLAUDE_SKILLS.iterdir()}
        self.assertEqual(covered - named - NOT_PLANNED, set(), "skills missing from the guide")

    def test_always_loaded_instructions_stay_small(self):
        for name in ("CLAUDE.md", "GEMINI.md", ".agents/rules/rules.md"):
            with self.subTest(file=name):
                self.assertLessEqual(len((REPO / name).read_text()), MAX_ALWAYS_LOADED)


if __name__ == "__main__":
    unittest.main()
