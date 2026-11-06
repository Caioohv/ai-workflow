---
name: executor-auto
description: Process pending steps sequentially with executor and Conventional Commits. Use fresh subagents when available, otherwise execute the skill in the current session. Report blocked items without retrying them during the run.
---

You run the step queue unattended: one step at a time, each in a fresh executor worker, one commit per finished step, until no eligible step remains.

## Before the first step

- Run `git status --porcelain`. Paths that are already dirty belong to the user: never stage them, and list them in the final report.
- Keep two lists for this run: `skipped` (paths not to retry) and `blocked` (slug + one-line cause + leftover changed paths).

## Loop

1. List `workflow/steps/todo/*.md` alphabetically, excluding `skipped`. If none are left, print the final report.
2. Start a fresh executor worker with only this prompt:
   > Read and follow `.agents/skills/executor/SKILL.md` to execute `workflow/steps/todo/<file>`. Blocked earlier in this run: <slug: cause; … or "none">.
3. Use its 6-line report. Don't re-read the step file.
4. Check the transition: `done`/`skipped` → the file is in `steps/done/`; `blocked` → back in `steps/todo/`. Anything else (file missing, still in `in-progress/`) counts as blocked with cause "unexpected state".
5. **done / skipped** → one commit:
   - Stage every changed path except the user's initial dirty paths and leftovers of steps blocked earlier in this run. Include the step file's move to `done/`.
   - Message: `<type>: <summary>` from the report. Add a scope only for a clear affected area (`feat(auth): …`), never the step slug. Add a body only if the notes call for it.
   - If a hook fails, fix the cause, re-stage and commit again. Never use `--no-verify`. If committing is impossible, stop and report the uncommitted step.
6. **blocked** → add it to `skipped` and `blocked` with its leftover changed paths (don't commit them), then continue.

## Harness compatibility

In Codex, use the available subagent tool with a general-purpose worker and the
explicit skill-file prompt above. Skills are not registered agent types. In
harnesses with named agents, use the corresponding named agent.

If subagent tools are unavailable, read and execute the executor skill directly
for each step and report that execution used the same session. Do not launch
nested CLI sessions to bypass the current harness's permissions.

## Rules

- Sequential only, a fresh worker per step when delegation is available. Never parallel: two agents must not touch the same files.
- Step file changes belong to the executor skill, including when you execute it directly because delegation is unavailable.

## Final report

```
## Steps: <n> done, <n> blocked

| Step | Outcome | Commit |
|------|---------|--------|
| 01-slug | done | abc1234 |

### Needs you
- `workflow/manual-tasks/03-create-db-user.md`: <what, where> (unblocks 04-connect-db)
- 05-slug blocked: <cause>; uncommitted changes: <paths or none>
- Your changes left untouched: <paths or none>
```

When something is blocked, end with: "Handle the items above and rerun the executor-auto skill: blocked steps are retried."
