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
  steps/
    todo/                # Steps ready to execute
    in-progress/         # Step currently being executed
    done/                # Completed steps (with execution summary)
  templates/
    task.md              # Unified task template
```

## Agents

### Task pipeline (structured development)

| Agent | Invocation | Description |
|-------|-----------|-------------|
| `initialize` | `/initialize` | Interactive project setup — creates `workflow/definition.md` |
| `spec-creator` | `/spec-creator <brief>` | Creates a task spec, may ask questions |
| `spec-creator-auto` | `/spec-creator-auto <brief>` | Creates a task spec autonomously |
| `implementer` | `/implementer <task-path>` | Implements a task, no commits |
| `implementer-ci` | `/implementer-ci <task-path>` | Implements with Conventional Commits |
| `implementer-auto` | `/implementer-auto` | Runs all todo tasks sequentially (unattended) |
| `reviewer` | `/reviewer <task-path>` | Reviews a task in to-review/, approves or rejects |

### Step pipeline (lightweight execution from a todo list)

| Agent | Invocation | Description |
|-------|-----------|-------------|
| `define-steps` | `/define-steps <todo.md>` | Expands a todo.md into step specs, may ask questions |
| `define-steps-auto` | `/define-steps-auto <todo.md>` | Expands a todo.md into step specs autonomously |
| `executor` | `/executor <step-path>` | Executes a single step, records summary when done |
| `executor-auto` | `/executor-auto` | Runs all steps in todo/ sequentially with Conventional Commits |

## Typical workflow

### Starting a project
```
/initialize
```
Walks through an interview to define the project. Creates `workflow/definition.md`.

### Task pipeline

#### Creating a task
```
/spec-creator add login with email and password
```
or, for background use:
```
/spec-creator-auto add login with email and password
```

#### Implementing a task
```
/implementer-ci workflow/tasks/todo/01-add-login.md
```
When done, the task moves to `workflow/tasks/to-review/`.

#### Reviewing
```
/reviewer workflow/tasks/to-review/01-add-login.md
```
Approved → `done/`. Rejected → new task created in `todo/`.

#### Fully automated (unattended)
```
/implementer-auto
```
Processes all tasks in `todo/`, runs reviewer after each, and loops until the queue is empty.

### Step pipeline

#### Defining steps from a todo list
```
/define-steps-auto examples/todo.md
```
Reads each line of the todo.md and creates a short step spec in `workflow/steps/todo/`.

#### Executing steps
```
/executor workflow/steps/todo/01-init-project.md
```
or, to run all steps unattended with commits:
```
/executor-auto
```

## Task lifecycle

```
todo/ → (implementer picks up) → in-progress/ → (done) → to-review/ → (reviewer) → done/
                                                                            ↓ rejected
                                                               new task created in todo/
```

## Step lifecycle

```
todo/ → (executor picks up) → in-progress/ → (done, summary appended) → done/
```

## Conventions

- Task filenames: zero-padded number + slug, hyphenated (e.g., `01-add-user-auth.md`, `02-fix-cart-total.md`)
- Step filenames: same convention (e.g., `01-init-project.md`, `02-write-endpoint.md`)
- One task = one coherent unit of work; one step = one line from the todo list
- `workflow/definition.md` is the single source of truth for project context — keep it current
- `workflow/project-memory.md` captures known gotchas — every agent reads it for context, and implementers/reviewers/executors append to it when they learn something non-obvious
