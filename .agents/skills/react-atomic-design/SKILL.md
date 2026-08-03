---
name: react-atomic-design
description: Use when writing or structuring React component code (.jsx/.tsx, function components) that should follow Atomic Design — organizing UI as atoms/molecules/organisms/sections, passing data top-down via props and composing with children/render props, and consuming design tokens through CSS variables (var(--...)). Triggers on React composition, atomic layering, and CSS-variable design tokens. Not for Vue (see the Vue sibling skill) or Nuxt (see nuxt-4-dev), and not for global state architecture, which belongs to a sibling skill.
---

You are writing React UI code that follows **Atomic Design** with **design tokens as CSS variables**. Apply this whenever you create or restructure React components. This skill decides the folder layout, naming, prop contract, and token wiring for you — follow the defaults below instead of inventing your own.

## What this skill decides for you (defaults, not options)

- **Function components only.** No class components. Use hooks for local behavior.
- **Data flows top-down via props.** A component never reaches for external/global state; whatever it renders comes from props. Lifting state up is the caller's job.
- **Composition over configuration.** Prefer `children` and slot/render props over ever-growing boolean flags.
- **Tokens are CSS variables.** Every color, font, space, radius, and size is `var(--token)`. Never a raw hex, px font-size, or magic spacing number in a component.
- **One component = one file = one folder**, co-locating its styles and test.

## Folder structure

```
src/
  styles/
    tokens.css          # :root design tokens — the single source of truth
  components/
    atoms/
      Button/
        Button.tsx
        Button.module.css
        Button.test.tsx
        index.ts        # re-export: export { Button } from './Button'
    molecules/
      Field/
        Field.tsx
        Field.module.css
        index.ts
    organisms/
      LoginForm/
        LoginForm.tsx
        index.ts
    sections/
      AuthSection/
        AuthSection.tsx
        index.ts
```

**Layer meaning (decide placement by this):**
- **atoms** — indivisible primitives with no dependency on other components (Button, Input, Text, Icon).
- **molecules** — a small group of atoms wired for one job (Field = Label + Input + error Text).
- **organisms** — a self-contained section of UI composed of molecules/atoms (LoginForm, Header, Card list).
- **sections** — page-level composition of organisms; receives data from the page/route and passes it down. No fetching logic beyond what props carry.

## Naming conventions

- Component + folder + file: `PascalCase` (`Button`, `LoginForm`).
- Props type: `ComponentNameProps` (`ButtonProps`).
- Boolean props read as adjectives/states: `isLoading`, `hasError`, `disabled`.
- Event props: `on` + verb (`onSubmit`, `onValueChange`).
- Variant/size are enumerated string props, never separate components: `variant="primary"`, not `PrimaryButton`.
- CSS Module classes: `camelCase` (`styles.root`, `styles.isDisabled`).
- Token names: `--color-*`, `--font-*`, `--space-*`, `--size-*`, `--radius-*`.

## Prop contract rules

- Type every component's props explicitly (`type Props = { ... }`).
- Accept `children: React.ReactNode` whenever the component wraps content — favor it over a `content` string prop.
- For multiple insertion points, use **named slots as render props or ReactNode props** (`header`, `footer`) instead of adding flags.
- Forward the underlying DOM props you don't own with `...rest`, and forward `ref` on atoms that map to a single element.
- Keep prop lists small: if an atom grows more than ~2 booleans that combine, collapse them into a single `variant` union.

## Design tokens (CSS variables)

Define tokens once in `styles/tokens.css`, imported once at the app root. Components only ever read them.

```css
/* styles/tokens.css */
:root {
  /* color */
  --color-primary: #2563eb;
  --color-on-primary: #ffffff;
  --color-text: #111827;
  --color-danger: #dc2626;

  /* typography */
  --font-sans: system-ui, sans-serif;
  --font-size-md: 1rem;
  --font-weight-bold: 600;

  /* spacing scale */
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;

  /* sizing & radius */
  --size-control-h: 2.5rem;
  --radius-md: 0.375rem;
}
```

## Examples (short, one per pattern)

**Atom** — reads tokens, forwards native props, variant not subclass:

```tsx
// atoms/Button/Button.tsx
import styles from './Button.module.css';

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'ghost';
  children: React.ReactNode;
};

export function Button({ variant = 'primary', children, ...rest }: ButtonProps) {
  return (
    <button className={`${styles.root} ${styles[variant]}`} {...rest}>
      {children}
    </button>
  );
}
```

```css
/* atoms/Button/Button.module.css */
.root {
  height: var(--size-control-h);
  padding: 0 var(--space-4);
  border-radius: var(--radius-md);
  font: var(--font-weight-bold) var(--font-size-md) var(--font-sans);
  border: none;
  cursor: pointer;
}
.primary { background: var(--color-primary); color: var(--color-on-primary); }
.ghost   { background: transparent; color: var(--color-primary); }
```

**Molecule** — composes atoms, data in via props, no state of its own:

```tsx
// molecules/Field/Field.tsx
import { Input } from '../../atoms/Input';
import styles from './Field.module.css';

type FieldProps = {
  label: string;
  error?: string;
  value: string;
  onValueChange: (v: string) => void;
};

export function Field({ label, error, value, onValueChange }: FieldProps) {
  return (
    <label className={styles.root}>
      <span className={styles.label}>{label}</span>
      <Input value={value} onChange={(e) => onValueChange(e.target.value)} />
      {error && <span className={styles.error}>{error}</span>}
    </label>
  );
}
```

**Organism** — composes molecules, exposes an `onSubmit` callback, holds only ephemeral form state, renders a `footer` slot via composition:

```tsx
// organisms/LoginForm/LoginForm.tsx
import { useState } from 'react';
import { Field } from '../../molecules/Field';
import { Button } from '../../atoms/Button';

type LoginFormProps = {
  onSubmit: (data: { email: string; password: string }) => void;
  footer?: React.ReactNode;
};

export function LoginForm({ onSubmit, footer }: LoginFormProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  return (
    <form onSubmit={(e) => { e.preventDefault(); onSubmit({ email, password }); }}>
      <Field label="Email" value={email} onValueChange={setEmail} />
      <Field label="Password" value={password} onValueChange={setPassword} />
      <Button type="submit">Sign in</Button>
      {footer}
    </form>
  );
}
```

## Checklist before you finish

- [ ] Component is a function component in its own PascalCase folder with an `index.ts` re-export
- [ ] Placed in the correct layer (atom/molecule/organism/section) by its dependencies
- [ ] All data arrives via props; nothing reaches into global state
- [ ] `children`/slot props used for composition instead of extra boolean flags
- [ ] No raw hex, px font-size, or magic spacing — every value is a `var(--token)`
- [ ] Variants/sizes are string-union props, not duplicated components

## Out of scope (belongs to sibling skills)

- **Concrete visual/aesthetic decisions** (which palette, exact scale values, look-and-feel) — a sibling design/aesthetics skill owns the token *values*; this skill only owns the token *mechanism*.
- **Global/app state architecture** (stores, context providers, data fetching/caching strategy) — a sibling state-architecture skill. Here, data always arrives as props.
- **Vue** (see the Vue Atomic Design sibling skill) and **Nuxt** (see `nuxt-4-dev`). This skill is React-only.
