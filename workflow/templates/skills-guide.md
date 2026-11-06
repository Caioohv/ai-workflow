# Skills guide

Planners (`define-steps`, `spec-creator`) use this to fill the **Skills** line of each step or task.
The worker loads exactly those skills before starting, so choose for the change being made, not for the topic.

## Rules

- Choose only skills available in this session (their names and descriptions are in your context): the framework skills below plus any the user installed. Never name a skill that isn't available.
- At most 3 per step or task. Each one costs context in the worker that loads it, so list a skill only if its rules change how this change is written. When more apply, keep the ones the change is most likely to get wrong. `secure-coding` counts toward the limit but is never the one dropped.
- Mechanical work (scaffolding, installing packages, moving or renaming files) usually needs none: write `—`.
- Use the framework skill that matches the stack in `definition.md` (Vue or React, Nest or Express).
- Skill preferences written in `definition.md` override this guide.

## By kind of change

| The change… | Skills |
|---|---|
| creates or restyles visible UI (page, component, layout, styles) | `frontend-components` + `vue-atomic-design` or `react-atomic-design` + `design-tools` |
| polishes or reviews how existing UI looks and reads, without new structure | `design-tools` (+ `frontend-components` if tokens change) |
| touches Nuxt data fetching, SSR, routeRules or server routes | `nuxt-4-dev` |
| decides where front-end state lives | `state-management` |
| adds or changes an endpoint, handler or middleware | `nestjs-backend` or `express-backend`; `api-design` for a new or changed contract; `api-responses` for response and error bodies |
| handles user input, auth, sessions, tokens, passwords, data access, uploads, outbound URLs, CORS or secrets | `secure-coding`, on top of the above |
| models business rules (entities, aggregates, invariants) | `ddd-tactical` |
| decides where code lives across layers | `clean-architecture` |
| changes schema, migrations, repositories or queries | `database-persistence` |
| adds or reads env vars or config | `env-config` |
| writes or changes tests | `testing-jest` |
| Dockerfile, compose or CI | `docker-ci` |
| user-facing PT-BR copy | `content-writer-ptbr` |
| a hard-to-reverse technical choice | `adr-decisions` |
| makes something faster or lighter | `performance` |
