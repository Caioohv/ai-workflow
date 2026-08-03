---
name: commit-pr-conventions
description: Use when writing a Git commit message or a Pull Request title/description — anytime you are about to author a commit, phrase a `type(scope): subject` line, or fill in a PR body. Enforces Conventional Commits 1.0.0 and a fixed PR description template so commits and PRs match what this repo's PR-review agent expects. Triggers on "commit message", "commit convention", "conventional commits", "PR description", "pull request title/body", "changelog-friendly commit". NOT the git/gh mechanics (staging, branching, pushing, opening the PR) and NOT the code-review itself — those belong to the review agent; this skill only defines the FORMAT of commit messages and PR descriptions.
---

You are writing a **commit message** or a **Pull Request description**. Produce output that follows **Conventional Commits 1.0.0** and the fixed PR template below, so the repo's PR-review agent can parse type/scope/breaking-changes and check the PR body against its expectations.

## Defaults this skill decides (do not ask, just apply)

- **Conventional Commits is mandatory.** Every commit and every PR title uses `type(scope): subject`.
- **Language: English, imperative mood.** Subjects and PR titles are written in English ("add", "fix", "remove"), not past tense, not Portuguese. (If the surrounding repo history is clearly Portuguese, mirror it — but English is the default.)
- **Subject length: ≤ 72 characters** (aim for ≤ 50). Hard cap 72.
- **PR template is fixed** — use the one in this file verbatim; do not invent sections.

## Commit format

```
type(scope): subject

<body — optional, wrapped at ~72 cols, explains WHAT and WHY, not how>

<footer — optional: BREAKING CHANGE:, Refs #123, Closes #123>
```

### Subject rules

- **Imperative mood**: "add login", not "added"/"adds"/"adding".
- **lowercase** first word; do not capitalize the subject.
- **No trailing period.**
- **≤ 72 chars** including the `type(scope): ` prefix.
- Say what the commit does, not the file names touched.

### Types — when to use each

| Type | Use for |
|------|---------|
| `feat` | a new feature / user-facing capability |
| `fix` | a bug fix |
| `docs` | documentation only |
| `style` | formatting, whitespace, semicolons — no code-behavior change |
| `refactor` | code change that neither fixes a bug nor adds a feature |
| `perf` | a change that improves performance |
| `test` | adding or correcting tests |
| `build` | build system or external dependencies (npm, webpack, Docker) |
| `ci` | CI configuration and scripts |
| `chore` | maintenance that doesn't touch src or tests (tooling, configs) |
| `revert` | reverts a previous commit |

- **scope** is optional, lowercase, a noun for the affected area: `feat(auth):`, `fix(cart):`. Omit when it doesn't help.

### Breaking changes

Signal a breaking change **both** ways when it matters:

- Add `!` after type/scope: `feat(api)!: ...`
- Add a `BREAKING CHANGE:` footer describing the break and the migration.

### Body & footer

- **Body** (optional): explain the motivation and contrast with previous behavior. Blank line after subject.
- **Footer** (optional): `BREAKING CHANGE: <desc>`, issue refs (`Closes #42`, `Refs #42`).

## Good commit examples (keep them short)

```
feat(auth): add email + password login
```

```
fix(cart): prevent negative totals on coupon stacking

Clamp the discounted subtotal at zero so overlapping coupons
can never produce a negative charge.

Closes #218
```

```
refactor(orders)!: replace positional args with an options object

BREAKING CHANGE: createOrder(userId, items) is now
createOrder({ userId, items }). Update all call sites.
```

```
chore(deps): bump eslint to 9.12
```

## Pull Request description

**Title**: same Conventional Commits format as a commit subject (`type(scope): subject`, ≤ 72 chars, imperative, lowercase, no period). For a squash-merge repo the PR title becomes the commit — keep it clean.

**Body**: copy this template verbatim and fill it in. Keep all four sections; write "N/A" rather than deleting one.

```markdown
## What & why
<!-- What this PR changes and the motivation. 1-3 sentences. -->

## How to test
<!-- Concrete steps a reviewer runs to verify. Commands, routes, expected result. -->
1.
2.

## Breaking changes
<!-- Describe any breaking change and the migration, or write "None". -->
None

## Checklist
- [ ] Follows Conventional Commits
- [ ] Tests added/updated (or N/A)
- [ ] Docs updated (or N/A)
- [ ] No secrets, debug logs, or commented-out code left behind

Closes #<issue>
```

- Reference the issue with `Closes #NN` (auto-closes on merge) or `Refs #NN` (links without closing).
- If the PR has no issue, drop the `Closes` line rather than leaving a dangling `#`.

## Out of scope

This skill defines the **format** only. It does NOT cover:

- **Git/gh mechanics** — staging, branching, `git commit`, `git push`, opening the PR with `gh`. Run those yourself; this skill just gives you the text.
- **The code review** — evaluating correctness, quality, or approving/rejecting. That is the PR-review agent's job; this skill only makes commits and PR bodies that the review agent can consume.
