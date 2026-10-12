<!-- ai-workflow:begin -->
# Codex AI Workflow

This project shares its task and step pipelines with Claude Code and Antigravity.
Use the skills in `.agents/skills/`; `.claude/agents/` and `.agents/rules/` are
configuration for the other harnesses, not Codex agent registrations or rules.

## Project context

- Read `workflow/definition.md` and `workflow/project-memory.md` before planning,
  implementing, executing, or reviewing work. If the definition is a placeholder,
  infer context from the repository; use `$discover` when asked to define it.
- For UI work, read `workflow/design.md` and apply `frontend-components` plus the
  framework skill. Use `$design-system` when the design system needs defining.
- Load relevant technical skills as needed rather than reading every skill.
- Record non-obvious solutions and gotchas in `workflow/project-memory.md`.

## Workflow entry points

Invoke a skill with `$skill-name` followed by its input, or ask for it by name.

| Goal | Skill and input |
|------|-----------------|
| Define the project | `$discover` |
| Define design tokens | `$design-system` |
| Create a task spec | `$spec-creator <brief>` or `$spec-creator-auto <brief>` |
| Implement one task without commits | `$implementer workflow/tasks/todo/NN-slug.md` |
| Implement one task with commits | `$implementer-ci workflow/tasks/todo/NN-slug.md` |
| Review an implementation | `$reviewer workflow/tasks/to-review/NN-slug.md` |
| Process all pending tasks | `$implementer-auto` |
| Plan a todo list | `$todo-planner <description>` |
| Expand a todo list | `$define-steps <todo-path>` or `$define-steps-auto <todo-path>` |
| Execute one step | `$executor workflow/steps/todo/NN-slug.md` |
| Process all pending steps with commits | `$executor-auto` |

## Shared state

- Tasks: `workflow/tasks/todo/` → `in-progress/` → `to-review/` → `done/`.
  Rejection creates a follow-up task in `todo/`; review itself does not fix code.
- Steps: `workflow/steps/todo/` → `in-progress/` → `done/`, with a summary appended.
- Todo lists: `workflow/todos/NN-slug-todo.md`, a flat numbered list consumed by
  `define-steps`. Specs use zero-padded numbers and hyphenated slugs.
- Use `workflow/templates/task.md` and `workflow/templates/design.md` where applicable.
- Advance statuses only after completing the corresponding work and verification.
  Report blockers and keep incomplete work out of `done/`.
- Direct requests do not require creating a spec or step unless the user asks for
  that pipeline. Keep existing workflow state intact when changing harnesses.

## Automated orchestration

When an auto skill is invoked, process items sequentially. If subagent tools are
available, create a fresh worker for each implementation/execution and a separate
worker for review. Give each worker the exact skill file to read, the item path,
and the shared context files; a skill name is not a registered Codex agent type.
Wait for completion and verify the expected file transition before proceeding.

If delegation is unavailable, follow the worker skill directly, then perform the
review as a separate pass. Disclose that review used the same session. Do not
claim an independent review or start nested Codex processes to bypass permissions.
Track skipped items so a blocker left in `todo/` is not retried forever. Stop
when no eligible items remain, and report any remaining blockers.

For commits, apply `commit-pr-conventions`, stage only changes belonging to the
current item, and include its workflow file transition. Preserve unrelated local
changes and respect the session's approval and sandbox settings.
<!-- ai-workflow:end -->
