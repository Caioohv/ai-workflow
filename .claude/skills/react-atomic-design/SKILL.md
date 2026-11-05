---
name: react-atomic-design
description: >-
  Compose React components (.jsx/.tsx) with Atomic Design: atoms, molecules,
  organisms, sections; data via props, composition with children, design
  tokens via CSS variables. Use for any React component structure.
---

You write **React** UI with **Atomic Design** and design tokens as CSS variables.

## Defaults (not options)

- Function components and hooks only.
- **Data top-down via props.** Atoms → organisms never import a store, context or query; sections/pages do and pass data down.
- **Composition over configuration:** `children` and ReactNode slot props (`header`, `footer`) instead of growing boolean flags.
- Every color, font, spacing, size and radius is `var(--token)` from `src/styles/tokens.css` (values come from `workflow/design.md`). No raw hex, `px` font sizes or magic numbers.
- One component per PascalCase folder: `Component.tsx`, `Component.module.css`, `Component.test.tsx`, `index.ts` re-export.

## Layers

```
src/components/
  atoms/       # no dependency on other components — Button, Input, Text, Icon
  molecules/   # a few atoms for one job — Field = label + Input + error
  organisms/   # self-contained UI block; may hold ephemeral UI/form state — LoginForm, Header
  sections/    # page-level composition; receives data from the page and passes it down
src/styles/tokens.css
```

## Naming and props

- Props type `ComponentNameProps`, always explicit.
- Booleans read as states (`isLoading`, `hasError`, `disabled`); callbacks `on` + verb (`onSubmit`, `onValueChange`).
- `variant`/`size` string unions, never separate components (`PrimaryButton` ✘). More than ~2 combinable booleans → collapse into a `variant`.
- Atoms that map to one element spread native props (`...rest`) and forward `ref`.
- CSS Module classes camelCase (`styles.root`); tokens named `--color-*`, `--font-*`, `--space-*`, `--size-*`, `--radius-*`.

## Example

```tsx
// atoms/Button/Button.tsx
import styles from './Button.module.css'

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'ghost'
  children: React.ReactNode
}

export function Button({ variant = 'primary', children, ...rest }: ButtonProps) {
  return <button className={`${styles.root} ${styles[variant]}`} {...rest}>{children}</button>
}
```

```css
/* atoms/Button/Button.module.css */
.root { height: var(--size-control-h); padding: 0 var(--space-4); border-radius: var(--radius-md); font: var(--font-weight-bold) var(--font-size-md) var(--font-sans); }
.primary { background: var(--color-primary); color: var(--color-on-primary); }
.ghost { background: transparent; color: var(--color-primary); }
```

```tsx
// organisms/LoginForm/LoginForm.tsx — ephemeral form state, intent emitted upward, footer slot
type LoginFormProps = { onSubmit: (d: { email: string; password: string }) => void; footer?: React.ReactNode }

export function LoginForm({ onSubmit, footer }: LoginFormProps) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  return (
    <form onSubmit={(e) => { e.preventDefault(); onSubmit({ email, password }) }}>
      <Field label="Email" value={email} onValueChange={setEmail} />
      <Field label="Password" value={password} onValueChange={setPassword} />
      <Button type="submit">Sign in</Button>
      {footer}
    </form>
  )
}
```

## Checklist

- [ ] Own PascalCase folder with `index.ts`; correct layer by its dependencies.
- [ ] Data via props; no global state below sections.
- [ ] `children`/slot props instead of extra flags; variants as unions.
- [ ] Every visual value is a `var(--token)`.

## Out of scope

- Token values and palette → `design-system` agent / `workflow/design.md`; reuse rules → `frontend-components`.
- Stores, context architecture, data fetching → `state-management`.
- Vue → `vue-atomic-design`; Nuxt → `nuxt-4-dev`.
