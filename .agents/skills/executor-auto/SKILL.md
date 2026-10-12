---
name: executor-auto
description: Process pending steps sequentially with executor and Conventional Commits. Use fresh subagents when available, otherwise execute the skill in the current session. Report blocked items without retrying them during the run.
---

You are the step execution orchestrator. You automatically process all pending steps one by one, delegating each to a fresh subagent, committing after each completes, and looping until `workflow/steps/todo/` is empty.

## Process

Keep a set of step paths skipped during this run. Repeat until
`workflow/steps/todo/` has no eligible `.md` files (excluding skipped paths):

1. List all eligible `.md` files in `workflow/steps/todo/`.
2. If none remain, stop and print the final summary table, including remaining blockers.
3. Take the first step (alphabetical order).
4. Spawn a fresh **executor** subagent:
   > "Read and follow `.agents/skills/executor/SKILL.md` to execute the step at `workflow/steps/todo/[filename]`. Read `workflow/definition.md` and `workflow/project-memory.md` if they exist for project context. Record any new gotchas in project memory."
5. Wait for completion and verify the step moved to `done/` with a summary. If blocked, failed, or the transition is missing, record the path as skipped and continue without committing it.
6. After the subagent completes, create a Conventional Commit for the work done:
   - Apply `.agents/skills/commit-pr-conventions/SKILL.md` and stage only changes belonging to this step, preserving unrelated local changes.
   - Commit with: `feat(<slug>): <one-line summary from step's Summary section>`
   - Also commit the step file move to `done/` in the same commit, or as a separate `chore` commit if cleaner.
7. If committing fails, stop and report the completed but uncommitted step before starting more work. Otherwise, select the next eligible step from the current queue.

## Harness compatibility

In Codex, use the available subagent tool with a general-purpose worker and the
explicit skill-file prompt above. Skills are not registered agent types. In
harnesses with named agents, use the corresponding named agent.

If subagent tools are unavailable, read and execute the executor skill directly
for each step and report that execution used the same session. Do not launch
nested CLI sessions to bypass the current harness's permissions.

## Commit format

```
<type>(<scope>): <description>

[optional body — only if the summary warrants it]
```

**Types:** `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `perf`, `test`

- Use the step slug as scope (e.g., `feat(init-npm-project): scaffold project with npm create`)
- Description: lowercase, imperative mood, no trailing period
- Moving a step file to `done/` can be bundled into the same commit or be its own `chore` commit

## Rules

- When delegation is available, use **fresh subagents** for each step.
- **Sequential only** — do not parallelize steps. One at a time.
- If a subagent fails or is blocked, log the issue and move on. Report all failures at the end.
- Step file changes belong to the executor skill, including when executing it directly because delegation is unavailable.
- Never use `--no-verify` or skip hooks. If a hook fails, fix the issue and retry.

## Final report

When no eligible steps remain, print (and list any remaining blockers):

```
## Steps complete

| Step | Outcome | Commit |
|------|---------|--------|
| slug | done / skipped | abc1234 |
```

List every step processed in this run.
