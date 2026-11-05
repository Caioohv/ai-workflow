---
name: vue-atomic-design
description: >-
  Compose Vue 3 components (SFC, `<script setup>`, Composition API) with
  Atomic Design: atoms, molecules, organisms, sections; typed props/emits,
  data top-down, design tokens as CSS custom properties. Use for any Vue
  component structure.
---

You write **Vue 3** UI with **Atomic Design**: compose upward, pass data down by props, read every visual value from CSS tokens.

## Defaults (do not re-litigate)

- Vue 3 SFC with `<script setup lang="ts">` and Composition API. No Options API.
- **Props down, events up.** Components never fetch, never import a store, never mutate a prop.
- Every color, font, spacing, size and radius is a `var(--token)` from `src/styles/tokens.css` (values come from `workflow/design.md`). No raw hex, `px` font sizes or magic numbers.
- `<style scoped>` in every component; global CSS only in the tokens file.
- Props typed with `defineProps<Props>()` + `withDefaults`; emits typed with `defineEmits<{...}>()`.

## Layers

```
src/components/
  atoms/       # one element, imports no component — BaseButton, BaseInput, BaseIcon
  molecules/   # composes atoms only — FormField, SearchBar
  organisms/   # composes molecules/atoms; may own local UI state (open, hover), never domain state — LoginForm, Header
  sections/    # arranges organisms for a page slot; the seam where the page passes data down
src/styles/tokens.css
```

A molecule that needs another molecule is an organism. Only sections/pages (or their container composables) read stores or queries.

## Naming and props

- Atoms prefixed `Base` (`BaseButton.vue`); others plain PascalCase; filename = component name.
- Props camelCase in script, kebab-case in templates; events kebab-case (`@submit`, `@update-value`).
- `v-model`-able atoms emit `update:modelValue`.
- Prefer `variant`/`size` unions over duplicated components (`BaseButtonBig` ✘).
- Required props have no default; don't drill data through layers for convenience: lift the composition instead.

## Example

```vue
<!-- atoms/BaseButton.vue -->
<script setup lang="ts">
interface Props { label: string; variant?: 'primary' | 'ghost'; disabled?: boolean }
withDefaults(defineProps<Props>(), { variant: 'primary', disabled: false })
defineEmits<{ click: [] }>()
</script>

<template>
  <button class="btn" :class="`btn--${variant}`" :disabled="disabled" @click="$emit('click')">{{ label }}</button>
</template>

<style scoped>
.btn { height: var(--size-control-h); padding: 0 var(--space-4); border-radius: var(--radius-md); font: var(--font-size-md) / var(--line-height-base) var(--font-sans); }
.btn--primary { background: var(--color-primary); color: var(--color-on-primary); }
.btn--ghost { background: transparent; color: var(--color-primary); }
</style>
```

```vue
<!-- molecules/FormField.vue -->
<script setup lang="ts">
defineProps<{ label: string; modelValue: string; error?: string }>()
defineEmits<{ 'update:modelValue': [value: string] }>()
</script>

<template>
  <label class="field">
    <span>{{ label }}</span>
    <BaseInput :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" />
    <span v-if="error" class="field__error">{{ error }}</span>
  </label>
</template>
```

## Checklist

- [ ] Correct layer by its composition rule.
- [ ] `<script setup lang="ts">` with typed props and emits.
- [ ] Data in via props, changes out via emits; no store, fetch or prop mutation.
- [ ] Every visual value is a `var(--token)`; `<style scoped>` present.

## Out of scope

- Token values and palette → `design-system` agent / `workflow/design.md`; reuse rules → `frontend-components`.
- Stores, data fetching, caching → `state-management`.
- Nuxt routing, SSR, Nitro → `nuxt-4-dev`. React → `react-atomic-design`.
