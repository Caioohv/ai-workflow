---
name: state-management
description: >-
  Frontend state: choose local vs URL vs server cache vs global store; Pinia
  (Vue/Nuxt), Zustand (React), TanStack Query; query keys, invalidation,
  optimistic updates. Triggers: store, Pinia, Zustand, global state, cache API
  data, prop drilling.
---

You are deciding where a piece of frontend state lives and wiring it. The goal: **each piece of state has exactly one owner, the smallest scope that works, and server data is cached, not copied.**

## 1. Classify the state first (decision table)

Before writing a store, put the state in one of these buckets. Most "global state" turns out to be server cache or URL state.

| Kind | Examples | Where it lives |
|------|----------|----------------|
| **Local UI** | open/closed, hover, input draft, current tab of one widget | `ref`/`useState` inside the organism/section that uses it |
| **URL** | filters, search term, pagination, selected tab that should survive reload/share | route query/params (`useRoute`/`useSearchParams`) — the URL *is* the store |
| **Server cache** | lists, entities, current user profile — anything the backend owns | TanStack Query (`@tanstack/vue-query` / `@tanstack/react-query`) or Nuxt `useFetch`/`useAsyncData` |
| **Form** | multi-field form values, dirty/touched, validation errors | local state or a form lib (VeeValidate, React Hook Form) scoped to the form |
| **Global client** | auth session token/flags, theme, cart before checkout, feature flags, toasts | a store: **Pinia** (Vue/Nuxt) or **Zustand** (React); Context only for rarely-changing values |

Rule: **if the backend is the source of truth, it's server cache — never copy it into a Pinia/Zustand store.** Copying creates two sources of truth that drift.

## 2. Server cache rules (TanStack Query / useFetch)

- **Query keys are structured and hierarchical:** `['orders', 'list', { status, page }]`, `['orders', 'detail', id]`. Centralize them in a key factory per resource (`orderKeys.list(filters)`), never inline string literals.
- **One composable/hook per query**, colocated with the feature: `useOrders(filters)`, `useOrder(id)`. Components never call `fetch`/`$fetch` for reads directly.
- **Mutations invalidate**, they don't hand-edit unrelated caches: `onSuccess: () => queryClient.invalidateQueries({ queryKey: orderKeys.all })`. Use `setQueryData` only for the entity you just changed.
- **Optimistic updates** follow the cancel → snapshot → set → rollback-on-error → invalidate-on-settled pattern. Only for actions where failure is rare and visible rollback is acceptable.
- Set `staleTime` deliberately per resource (reference data: minutes/hours; live data: 0–30s). Default `0` causes refetch storms.
- Always render all three states: `isPending` (skeleton), `isError` (human message per `api-responses`), success. Empty list is a fourth state — design it.
- In Nuxt, prefer `useFetch`/`useAsyncData` for SSR page data (see `nuxt-4-dev`); use vue-query only if the project already adopted it — don't mix both for the same resource.

## 3. Global store rules (Pinia / Zustand)

- **One store per domain concern** (`useAuthStore`, `useCartStore`), not one god-store. Name by noun, file per store under `stores/`.
- **Pinia:** use setup syntax (`defineStore('cart', () => { ... })`); expose state as `ref`, derived as `computed`, changes as functions. Destructure in components with `storeToRefs()` — plain destructuring loses reactivity.
- **Zustand:** one `create()` per store; components subscribe with **selectors** (`useCart(s => s.items)`), never the whole store, to avoid re-render storms. Actions live inside the store.
- **Derived state is computed, never stored.** `total` is a getter over `items`, not a field kept in sync by hand.
- **State changes only through store actions**; no component mutates store state directly (Pinia allows it — don't).
- Stores hold **serializable data** (no class instances, DOM nodes, promises). Persist (`pinia-plugin-persistedstate`, `zustand/middleware/persist`) only an explicit allow-list of keys; **never persist tokens to localStorage** if an httpOnly cookie is possible (see `secure-coding`).
- **SSR (Nuxt/Next):** stores must be per-request. Pinia via `@pinia/nuxt` handles it; never create module-level singletons holding user data.

## 4. Where stores are read (ties into Atomic Design)

- **Atoms, molecules, organisms stay presentational:** they receive data by props and emit events. They never import a store or a query.
- **Sections/pages (or a container composable) are the only layer that reads stores/queries** and passes data down. This keeps components reusable and testable.

```ts
// features/orders/useOrders.ts (Vue + vue-query)
export const orderKeys = {
  all: ['orders'] as const,
  list: (f: OrderFilters) => [...orderKeys.all, 'list', f] as const,
  detail: (id: string) => [...orderKeys.all, 'detail', id] as const,
}
export function useOrders(filters: MaybeRef<OrderFilters>) {
  return useQuery({
    queryKey: computed(() => orderKeys.list(unref(filters))),
    queryFn: () => api.orders.list(unref(filters)),
    staleTime: 30_000,
  })
}
```

```ts
// stores/cart.ts (Pinia, setup syntax)
export const useCartStore = defineStore('cart', () => {
  const items = ref<CartItem[]>([])
  const total = computed(() => items.value.reduce((s, i) => s + i.price * i.qty, 0))
  function add(item: CartItem) { /* merge qty or push */ }
  function clear() { items.value = [] }
  return { items, total, add, clear }
})
```

## Checklist before finishing

- [ ] Each new piece of state was classified (local / URL / server cache / form / global) and lives in that bucket.
- [ ] No server data duplicated into a client store.
- [ ] Query keys come from a key factory; mutations invalidate the affected keys.
- [ ] Loading, error and empty states are rendered.
- [ ] Derived values are computed, not stored; changes go through actions.
- [ ] Presentational components (atoms → organisms) do not import stores or queries.
- [ ] Nothing sensitive is persisted to browser storage; stores are per-request under SSR.

## Out of scope (hand off)

- Component layering and prop/emit contracts → `vue-atomic-design` / `react-atomic-design`.
- Nuxt SSR mechanics (`useState`, payload, hydration, `useFetch` options) → `nuxt-4-dev`.
- Business rules and invariants → `ddd-tactical` (the frontend mirrors them, it doesn't own them).
- Response body shape from the API → `api-responses`; endpoint/contract design → `api-design`.
