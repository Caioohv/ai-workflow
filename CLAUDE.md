# AI Workflow

This project uses a structured AI-assisted development workflow. Tasks move through a pipeline managed by specialized agents.

## Directory structure

```
workflow/
  definition.md          # Project definition (created by initialize agent)
  project-memory.md      # Known gotchas — running log agents read/append across tasks
  tasks/
    todo/                # Ready to implement
    in-progress/         # Currently being worked on
    to-review/           # Awaiting review
    done/                # Completed
  templates/
    task.md              # Unified task template
```

## Agents

| Agent | Invocation | Description |
|-------|-----------|-------------|
| `initialize` | `/initialize` | Interactive project setup — creates `workflow/definition.md` |
| `spec-creator` | `/spec-creator <brief>` | Creates a task spec, may ask questions |
| `spec-creator-auto` | `/spec-creator-auto <brief>` | Creates a task spec autonomously |
| `implementer` | `/implementer <task-path>` | Implements a task, no commits |
| `implementer-ci` | `/implementer-ci <task-path>` | Implements with Conventional Commits |
| `implementer-auto` | `/implementer-auto` | Runs all todo tasks sequentially (unattended) |
| `reviewer` | `/reviewer <task-path>` | Reviews a task in to-review/, approves or rejects |

## Typical workflow

### Starting a project
```
/initialize
```
Walks through an interview to define the project. Creates `workflow/definition.md`.

### Creating a task
```
/spec-creator add login with email and password
```
or, for background use:
```
/spec-creator-auto add login with email and password
```

### Implementing a task
```
/implementer-ci workflow/tasks/todo/01-add-login.md
```
When done, the task moves to `workflow/tasks/to-review/`.

### Reviewing
```
/reviewer workflow/tasks/to-review/01-add-login.md
```
Approved → `done/`. Rejected → new task created in `todo/`.

### Fully automated (unattended)
```
/implementer-auto
```
Processes all tasks in `todo/`, runs reviewer after each, and loops until the queue is empty.

## Task lifecycle

```
todo/ → (implementer picks up) → in-progress/ → (done) → to-review/ → (reviewer) → done/
                                                                            ↓ rejected
                                                               new task created in todo/
```

## Conventions

- Task filenames: zero-padded number + slug, hyphenated (e.g., `01-add-user-auth.md`, `02-fix-cart-total.md`)
- One task = one coherent unit of work
- `workflow/definition.md` is the single source of truth for project context — keep it current
- `workflow/project-memory.md` captures known gotchas — every agent reads it for context, and implementers/reviewers append to it when they learn something non-obvious (error fixes, quirks, constraints)
