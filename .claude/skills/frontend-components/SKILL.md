---
name: frontend-components
description: Use when building or modifying any frontend/UI code. Favors reusable, composable components over duplication and enforces the design system defined in workflow/design.md (colors, typography, spacing, radii — no hardcoded values).
---

You are working on frontend/UI code. Default to **reusable, composable components** and follow the project's design system in `workflow/design.md`. Apply this whenever you create or change anything the user sees — pages, screens, components, or styles.

## Before you write any UI

1. **Read `workflow/design.md`.** It is the single source of truth for colors, typography, spacing, radii, shadows, and component conventions.
   - If it does not exist, stop and tell the user to run the `design-system` agent first (`/design-system`). Do not invent ad-hoc colors or scales.
2. **Search before you create.** Look through the existing component directory (`components/`, `ui/`, `src/components/`, etc.) for something that already does the job — and check the existing naming conventions before inventing your own.

## Reuse hierarchy

Always prefer, in this order:

1. **Reuse** an existing component as-is.
2. **Extend** an existing component with a new prop/variant — only when it's a natural variation, not a different concern.
3. **Compose** smaller existing components into a new one.
4. **Create** a new component — last resort, only when the pattern is genuinely new.

If you catch yourself copy-pasting markup or styles, stop and extract a component instead.

## When you create a component

- **Single responsibility** — one component, one job. Split when it grows two unrelated concerns.
- **Configurable through props/variants**, not forks. Prefer a `variant`/`size` prop over `ButtonRed`, `ButtonBig`.
- **No hardcoded design values.** Pull every color, font, space, radius, and shadow from the tokens in `design.md` (CSS variables, Tailwind theme keys, or the project's token object). Never paste a raw hex, a px font-size, or a one-off spacing value.
- **Accessible by default** — semantic elements, labels, visible focus states, keyboard support.
- **Co-locate** styles/tests following the project's existing structure.

## Design adherence checklist

- [ ] Colors come from design tokens — no raw hex/rgb in the component
- [ ] Typography uses the type scale from `design.md` — no arbitrary font sizes/weights
- [ ] Spacing/sizing use the spacing scale — no magic numbers
- [ ] Border radius and shadows use the defined tokens
- [ ] States (hover/focus/active/disabled) follow the design system
- [ ] The component reuses primitives (Button, Input, …) instead of re-styling from scratch

## Anti-patterns to avoid

- Copy-pasting an existing component to tweak one thing → extend or compose instead.
- Inline styles with magic numbers (`style={{ margin: 13 }}`) → use the spacing scale.
- One-off colors that "look close enough" → use the palette in `design.md`.
- A new component that duplicates ~80% of an existing one → add a variant.
- Diverging from the design system "just this once" → if the system is missing something, update `design.md` (or run the `design-system` agent) so the decision is captured for everyone.

## Output

When you finish, briefly note which existing components you reused and any new reusable component you introduced (name + purpose), so the catalogue stays discoverable.
