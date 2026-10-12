---
name: implementer-auto
description: Process pending tasks sequentially with implementer-ci and reviewer. Use fresh subagents when available, otherwise execute the skills in the current session. Report blocked items without retrying them during the run.
---

You are the workflow orchestrator. You automatically process all pending tasks, delegating each one to fresh subagents and looping until the queue is empty.

## Process

Keep a set of task paths skipped during this run. Repeat until
`workflow/tasks/todo/` has no eligible `.md` files (excluding skipped paths):

1. List all eligible `.md` files in `workflow/tasks/todo/`.
2. If none remain, stop and print the final summary table, including remaining blockers.
3. Take the first task (alphabetical order).
4. Spawn a fresh **implementer-ci** subagent:
   > "Read and follow `.agents/skills/implementer-ci/SKILL.md` to implement the task at `workflow/tasks/todo/[filename]`. Read `workflow/definition.md` and `workflow/project-memory.md` for project context, and record any new gotchas in project memory."
5. Wait for completion and verify the task moved to `to-review/`. If blocked, failed, or the transition is missing, record the path as skipped and continue without reviewing it.
6. Spawn a fresh **reviewer** subagent:
   > "Read and follow `.agents/skills/reviewer/SKILL.md` to review the task at `workflow/tasks/to-review/[filename]`. Read `workflow/definition.md` and `workflow/project-memory.md` for project context."
7. Wait for completion and verify the task moved to `done/`. If review fails or is blocked, log the unfinished review and continue; do not report it as approved.
8. If the reviewer created a new task in `workflow/tasks/todo/`, go back to step 1 (pick up the new task in the next iteration).
9. Return to step 1 to select the next eligible task from the current queue.

## Harness compatibility

In Codex, use the available subagent tool with a general-purpose worker and the
explicit skill-file prompt above. Skills are not registered agent types. In
harnesses with named agents, use the corresponding named agent.

If subagent tools are unavailable, read and execute the worker skill directly,
then read the reviewer skill and perform a separate review pass. Report that the
review ran in the same session. Do not launch nested CLI sessions to bypass the
current harness's permissions.

## Rules

- When delegation is available, use **fresh subagents** for each implementation and review.
- **Sequential only** — do not parallelize tasks. One at a time.
- If a subagent fails or is blocked, log the issue and move on. Report all failures at the end.
- Task file changes belong to the implementer and reviewer skills, including when executing those skills directly because delegation is unavailable.

## Final report

When no eligible tasks remain, print (and list any unfinished reviews or blockers):

```
## Workflow complete

| Task | Outcome | Notes |
|------|---------|-------|
| slug | done / skipped / rejected→requeued | ... |
```

List every task processed in this run, including follow-ups created by the reviewer.
