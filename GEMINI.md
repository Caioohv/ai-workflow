<!-- ai-workflow:begin -->
# Antigravity AI Workflow

Structured AI-assisted development. Work moves through file-based pipelines in `workflow/`. Each pipeline command is a skill in `.agents/skills/`, invoked as `/<name> <args>` (e.g. `/spec-creator add login`). Unsure what's next → `/orchestrator`.

## workflow/

```
definition.md      project definition, single source of truth (/discover) — keep it current
project-memory.md  known gotchas — read before working, append when you learn something non-obvious
decisions/         ADRs: why significant choices were made (adr-decisions skill)
design.md          design tokens (/design-system) — required before building UI
manual-tasks/      instructions for actions only the user can do
todos/             NN-slug-todo.md lists (/todo-planner)
tasks/{todo,in-progress,to-review,done}/
steps/{todo,in-progress,done}/
templates/         task.md, design.md, manual-task.md, adr.md, skills-guide.md
verify.sh          runs the project's lint, typecheck, test and build with compact output
```

## Pipelines

- **Tasks:** `/spec-creator[-auto] <brief>` → `todo/` → `/implementer[-ci] <task>` → `in-progress/` → `to-review/` → `/reviewer <task>` → `done/`. Rejection moves the original to `done/` and creates a follow-up in `todo/`. `/implementer-auto` runs the whole queue with review after each task.
- **Steps:** `/todo-planner <description>` → `todos/NN-slug-todo.md` → `/define-steps[-auto] <todo>` → `steps/todo/` → `/executor <step>` → `in-progress/` → `done/` (summary appended), or back to `todo/` with a `## Blocked` note so the next run retries it. `/executor-auto` runs all steps with Conventional Commits.
- **Other commands:** `/discover` (definition.md), `/design-system` (design.md). For a read-only security review, use the `secure-coding` skill's audit mode.

## Conventions

- Filenames: zero-padded number + hyphenated slug (`01-add-user-auth.md`); todo lists add `-todo`.
- One task = one coherent unit of work; one step = one line of a todo list (a flat numbered list of small, verifiable steps).
- Advance a status only after the work **and its verification** pass: run `workflow/verify.sh` (or the stack's checks with trimmed output); never paste full logs.
- Read `definition.md`, `project-memory.md` and the relevant ADRs before planning, implementing or reviewing.
- Significant, hard-to-reverse technical decisions become ADRs in `decisions/`; supersede, never edit, an accepted ADR.
- Whenever the user must act (server access, DB setup, credentials, third-party services), create `workflow/manual-tasks/NN-slug.md` from `templates/manual-task.md` (copy-paste commands grouped by where to run them, real project values, a check, what it unblocks) and tell the user.

## Skills

Technical skills in `.agents/skills/` load on demand. They are orthogonal and composable: architecture skills are framework-agnostic, framework skills cover only mechanics and delegate architecture (Nest + DDD load together without conflict). Each skill's "Out of scope" names the sibling that owns the rest. Steps and tasks name the skills their worker must load in a **Skills** line, chosen with `templates/skills-guide.md`.
<!-- ai-workflow:end -->
