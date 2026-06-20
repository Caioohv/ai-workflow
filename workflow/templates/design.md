# Design System — [Nome do Projeto]

**Status:** `draft` | `approved`
**Atualizado em:** YYYY-MM-DD
**Stack de estilo:** Tailwind | CSS variables | CSS-in-JS | ...

> Fonte única de verdade para a UI. O skill `frontend-components` constrói com base
> nestes tokens — nada de cores, fontes ou espaçamentos hardcoded fora daqui.

---

## Princípios

> 2 a 4 frases sobre a personalidade visual (ex.: minimalista, confiável, com bastante respiro).

---

## Cores

| Token | Valor | Uso |
|-------|-------|-----|
| `color-primary` | `#......` | Ações principais, links, destaque de marca |
| `color-accent` | `#......` | Apoio ao primário |
| `color-bg` | `#......` | Fundo da página |
| `color-surface` | `#......` | Cards, modais, superfícies elevadas |
| `color-border` | `#......` | Bordas e divisórias |
| `color-text` | `#......` | Texto principal |
| `color-text-muted` | `#......` | Texto secundário |
| `color-success` | `#......` | Sucesso |
| `color-warning` | `#......` | Atenção |
| `color-danger` | `#......` | Erro / ação destrutiva |
| `color-info` | `#......` | Informativo |

**Contraste (WCAG AA):**
- texto sobre fundo: `X:1`
- texto sobre superfície: `X:1`

---

## Tipografia

- **Heading:** `[Fonte]` — pesos [...]
- **Body:** `[Fonte]` — pesos [...]

| Token | Tamanho / line-height | Uso |
|-------|----------------------|-----|
| `text-xs` | | Labels, legendas |
| `text-sm` | | Texto auxiliar |
| `text-base` | | Corpo |
| `text-lg` | | Subtítulos |
| `text-xl`+ | | Títulos |

---

## Espaçamento

> Escala consistente baseada em [base]px.

`space-1 = 4px` · `space-2 = 8px` · `space-3 = 12px` · `space-4 = 16px` · `space-6 = 24px` · `space-8 = 32px` · ...

---

## Raios e bordas

| Token | Valor | Uso |
|-------|-------|-----|
| `radius-sm` | | Inputs, badges |
| `radius-md` | | Botões, cards |
| `radius-lg` | | Modais |
| `radius-full` | `9999px` | Pílulas, avatares |

---

## Sombras / elevação

| Token | Valor | Uso |
|-------|-------|-----|
| `shadow-sm` | | Elevação sutil |
| `shadow-md` | | Cards, dropdowns |
| `shadow-lg` | | Modais, popovers |

---

## Breakpoints e movimento

- **Breakpoints:** `sm` · `md` · `lg` · `xl`
- **Durações:** rápida `[ms]` · padrão `[ms]`
- **Easing:** `[curva]`

---

## Tokens (código)

> Cole aqui os tokens no formato da stack (ex.: `theme.extend` do Tailwind,
> `:root` com CSS variables, ou um objeto de tokens em JS).

```
/* ... */
```

---

## Padrões de componente

> Convenções para componentes reutilizáveis (variantes, estados, naming).

- **Botões:** variantes `primary | secondary | ghost | danger`; estados hover/focus/disabled.
- **Inputs:** ...
- **...**

---

## Do / Don't

- ✅ Sempre usar os tokens acima.
- ✅ Estender componentes via props/variants.
- ❌ Hex, px de fonte ou espaçamentos soltos no JSX/CSS.
- ❌ Cores "quase iguais" fora da paleta.
