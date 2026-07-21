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
  design.md              # Design system tokens (created by design-system agent)
  templates/
    task.md              # Unified task template
    design.md            # Design system template
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
| `design-system` | `/design-system` | Defines the design system (colors, typography, spacing) — creates `workflow/design.md` |

### Step pipeline (lightweight execution from a todo list)

| Agent | Invocation | Description |
|-------|-----------|-------------|
| `define-steps` | `/define-steps <todo.md>` | Expands a todo.md into step specs, may ask questions |
| `define-steps-auto` | `/define-steps-auto <todo.md>` | Expands a todo.md into step specs autonomously |
| `executor` | `/executor <step-path>` | Executes a single step, records summary when done |
| `executor-auto` | `/executor-auto` | Runs all steps in todo/ sequentially with Conventional Commits |

## Skills

Skills apply automatically when you touch related code. They are **orthogonal and composable**: architecture skills are framework-agnostic; framework skills cover only framework mechanics and delegate architecture to the architecture skills (e.g. "Nest + DDD" loads both without conflict).

| Skill | Applies when |
|-------|--------------|
| `clean-architecture` | Deciding which layer code lives in and which way dependencies point (entities/use cases/adapters, ports & adapters, Dependency Rule) |
| `ddd-tactical` | Modeling the domain — Entity vs Value Object, Aggregates and invariants, Repository, Domain Events/Services, Factories |
| `express-backend` | Structuring Express code — routers, middleware order, thin controllers, request-id logger |
| `nestjs-backend` | Writing NestJS code — modules, providers, DI, pipes/guards/interceptors/filters, logging |
| `api-responses` | Writing endpoint responses (JS/Node) — human-friendly, no leaking of internals |
| `frontend-components` | Creating/altering UI — component reuse and adherence to `workflow/design.md` tokens (nothing hardcoded) |
| `vue-atomic-design` | Composing Vue 3 components (SFC, `<script setup>`) with Atomic Design |
| `react-atomic-design` | Composing React components (`.jsx`/`.tsx`) with Atomic Design |
| `nuxt-4-dev` | Writing Nuxt 4 — data fetching, SSR, server routes (Nitro), hydration |
| `testing-jest` | Writing Jest tests — what to test and what to mock per layer (domain, use case, repo, controller) |
| `security-audit-node` | Auditing security of Node/Express/Nest code — findings report (OWASP); does not write code |
| `commit-pr-conventions` | Writing a commit message or PR title/description — Conventional Commits + PR template |
| `content-writer-ptbr` | Writing textual content in PT-BR (titles, copy, microcopy) — strict style rules |

Define the design system with `/design-system` before building the frontend — the `frontend-components` skill reads `workflow/design.md` as the single source of truth.

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
