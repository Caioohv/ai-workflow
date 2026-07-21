---
name: vue-atomic-design
description: >-
  Use when writing or restructuring Vue 3 component code (SFC, `<script setup>`,
  Composition API) and organizing it with Atomic Design — atoms → molecules →
  organisms → sections — with data flowing top-down via props and design tokens
  declared as CSS custom properties. Triggers on Vue component composition,
  atomic folder structure, prop contracts, and CSS `:root` token definitions.
  Not for React (see the React sibling skill), not for Nuxt framework mechanics
  (see nuxt-4-dev), and not for global state architecture (Pinia/stores/DDD) or
  concrete visual aesthetics (palette/brand choices) — those belong to sibling
  skills.
---

You are writing **Vue 3** UI and organizing it with **Atomic Design**. Compose small components upward, pass data down through props, and read every visual value from CSS design tokens. This skill decides composition and tokens; it deliberately does not decide aesthetics or global state.

## What this skill decides for you (defaults — do not re-litigate)

- **Vue 3 + SFC + `<script setup>` + Composition API.** No Options API, no `.jsx`.
- **Atomic layering** with the exact folder names below.
- **Props-down, events-up.** Data enters a component only through props. Components never fetch, never reach into a store, never mutate a prop.
- **All visual values are CSS custom properties** declared in `:root`. No raw hex, no `px` font sizes, no magic spacing numbers inside a component.
- **`<style scoped>`** in every component; global styles live only in the token file.
- **TypeScript** for props via `defineProps<...>()` with `withDefaults`.

## Folder structure

```
src/components/
  atoms/        # indivisible primitives — BaseButton, BaseInput, BaseIcon, BaseText
  molecules/    # 2–5 atoms wired together — FormField, SearchBar, Card
  organisms/    # self-contained UI regions — Header, ProductList, LoginForm
  sections/     # page-level compositions of organisms — HeroSection, DashboardSection
src/styles/
  tokens.css    # :root design tokens (imported once, globally)
```

Rules for placement:
- An **atom** renders one element/concept and imports no other component.
- A **molecule** composes atoms only. If it needs another molecule, it is an organism.
- An **organism** composes molecules/atoms into a meaningful block; it may own local UI state (open/closed, hovered) but no domain/business state.
- A **section** arranges organisms for a page slot; it is the seam where a page/route passes data down.

## Naming conventions

- Atoms are prefixed `Base` (`BaseButton.vue`, `BaseInput.vue`).
- Molecules/organisms/sections use plain PascalCase describing the thing (`FormField.vue`, `LoginForm.vue`, `HeroSection.vue`).
- One component per file; filename === component name.
- Props: camelCase in `<script>`, kebab-case in templates. Events: past-tense kebab (`@update-value`, `@submit`).
- Emit updates with `update:modelValue` for two-way-bindable atoms so `v-model` works.

## Prop contract

- Type every prop with `defineProps<Props>()`; never the array/loose-object form.
- Give optional props defaults via `withDefaults`. Required props have no default.
- Props are **read-only**. To change a value, `emit` an event and let the owner update it.
- Prefer a small closed set: `variant` / `size` props over duplicated components (`BaseButtonBig`).
- No prop drilling more than one layer for convenience — if data skips layers, lift the composition up.

## Examples

### Design tokens — `src/styles/tokens.css`

Declare tokens once; every component consumes them. This skill owns the *token contract*, not the concrete values.

```css
:root {
  /* color (roles, not raw names) */
  --color-primary: #2563eb;
  --color-text: #1f2937;
  --color-surface: #ffffff;

  /* typography */
  --font-sans: system-ui, sans-serif;
  --font-size-sm: 0.875rem;
  --font-size-md: 1rem;
  --font-size-lg: 1.25rem;
  --line-height-base: 1.5;

  /* spacing scale (4px base) */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;

  /* sizing / radius */
  --size-control-h: 2.5rem;
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
}
```

### Atom — `atoms/BaseButton.vue`

```vue
<script setup lang="ts">
interface Props {
  label: string
  variant?: 'primary' | 'ghost'
  disabled?: boolean
}
withDefaults(defineProps<Props>(), { variant: 'primary', disabled: false })
defineEmits<{ click: [] }>()
</script>

<template>
  <button
    class="btn"
    :class="`btn--${variant}`"
    :disabled="disabled"
    @click="$emit('click')"
  >
    {{ label }}
  </button>
</template>

<style scoped>
.btn {
  height: var(--size-control-h);
  padding: 0 var(--space-4);
  font: var(--font-size-md) / var(--line-height-base) var(--font-sans);
  border: none;
  border-radius: var(--radius-md);
  cursor: pointer;
}
.btn--primary { background: var(--color-primary); color: var(--color-surface); }
.btn--ghost   { background: transparent; color: var(--color-primary); }
.btn:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
```

### Molecule — `molecules/FormField.vue`

Composes atoms; passes data down, forwards the change event up.

```vue
<script setup lang="ts">
import BaseInput from '../atoms/BaseInput.vue'

interface Props {
  label: string
  modelValue: string
  error?: string
}
defineProps<Props>()
defineEmits<{ 'update:modelValue': [value: string] }>()
</script>

<template>
  <label class="field">
    <span class="field__label">{{ label }}</span>
    <BaseInput
      :model-value="modelValue"
      @update:model-value="$emit('update:modelValue', $event)"
    />
    <span v-if="error" class="field__error">{{ error }}</span>
  </label>
</template>

<style scoped>
.field { display: flex; flex-direction: column; gap: var(--space-2); }
.field__label { font-size: var(--font-size-sm); color: var(--color-text); }
.field__error { font-size: var(--font-size-sm); color: var(--color-primary); }
</style>
```

### Organism — `organisms/LoginForm.vue`

Composes molecules, owns only local UI state, emits the domain intent upward.

```vue
<script setup lang="ts">
import { ref } from 'vue'
import FormField from '../molecules/FormField.vue'
import BaseButton from '../atoms/BaseButton.vue'

interface Props { submitting?: boolean }
withDefaults(defineProps<Props>(), { submitting: false })
const emit = defineEmits<{ submit: [payload: { email: string; password: string }] }>()

const email = ref('')
const password = ref('')
</script>

<template>
  <form class="login" @submit.prevent="emit('submit', { email, password })">
    <FormField label="Email" v-model="email" />
    <FormField label="Password" v-model="password" />
    <BaseButton :label="submitting ? 'Signing in…' : 'Sign in'" :disabled="submitting" />
  </form>
</template>

<style scoped>
.login { display: flex; flex-direction: column; gap: var(--space-4); }
</style>
```

## Checklist before finishing

- [ ] Component sits in the correct layer (atom/molecule/organism/section) by its composition rule.
- [ ] `<script setup lang="ts">` with typed `defineProps` / `defineEmits`.
- [ ] Data comes in via props only; changes go out via emits — no store access, no fetch, no prop mutation.
- [ ] Every color/font/space/size/radius reads a `var(--token)` — no raw hex, px, or magic numbers.
- [ ] `<style scoped>` present; no global CSS outside `tokens.css`.
- [ ] `v-model`-able atoms use `update:modelValue`.

## Out of scope (hand off to sibling skills)

- **Concrete visual aesthetics** — the actual palette, brand colors, type choices, spacing values. This skill defines the *token contract* (`--color-primary`, `--space-4`); it does not pick what they equal.
- **Global state architecture** — Pinia/stores, data fetching, caching, domain modeling. Components here stay presentational.
- **React** — same pattern, different skill (React sibling).
- **Nuxt framework mechanics** — routing, SSR, Nitro, data fetching → `nuxt-4-dev`.
