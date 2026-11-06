---
name: design-tools
description: >-
  Visual and UX craft for UI: pick the surface mode (app, landing, docs), then
  build and self-check hierarchy, type, spacing, color, motion, states and copy
  against an anti-template list. Use when creating, restyling, polishing or
  reviewing a page or component, or when UI looks generic or "AI-made".
---

You make UI look designed for this product, not assembled from defaults. `frontend-components` owns tokens and reuse, the atomic skills own component structure; this skill decides how it looks and reads, then checks the result.

## Context (never interview)

- Product, audience and tone come from `workflow/definition.md`. The visual system is `workflow/design.md`: its tokens are the only palette, type scale, spacing, radii and shadows.
- No `design.md` → stay inside the existing look and note in the report that `/design-system` is pending. Don't invent a new visual world.
- Don't create other design context files (PRODUCT.md, DESIGN.md, …) and don't stop to ask. Anything the brief leaves open → the option most consistent with existing screens, noted in the report.
- **Refine keeps, redesign replaces.** Refining keeps identity, behavior, copy and everything out of scope. Only work that explicitly says redesign replaces the look.

## 1. Pick the mode from the surface, not the product

| Mode | Surfaces | Success | Ambition shows as |
|------|----------|---------|-------------------|
| Operate | app screens, dashboards, admin, settings, forms | the task gets done fast, without errors | precision, consistency, density that scans, familiar patterns |
| Persuade | landing, marketing, pricing, signup | the visitor gets the offer and acts | one idea per screen, the real product, a strong first screen |
| Read | docs, articles, help, changelog | the content is understood | measure, rhythm, structure, navigation |

A SaaS landing page is Persuade; the same SaaS settings page is Operate.

## 2. Build

- **Hierarchy:** one primary action per view. The most important thing is the strongest. Tight spacing inside a group, generous between groups, more space above a heading than below it.
- **Type:** body measure 60–75ch, clear size and weight steps from the scale, balanced headings (`text-wrap: balance`), tabular numerals in data.
- **Color:** neutrals carry the page; the accent marks action and state. Secondary text on a colored surface is tinted from that surface, not gray. Contrast ≥ 4.5:1 for body text, ≥ 3:1 for large text and UI.
- **Depth:** shadows from tokens, with offset and soft blur; no colored glow as decoration.
- **Motion:** few, purposeful, ease-out 150–300 ms. Every interactive element answers hover and press. Content is visible without animation, and `prefers-reduced-motion` rests everything.
- **States:** hover, `focus-visible`, active and disabled on every control; loading, empty and error on every data view; inline validation that names the fix.
- **Copy:** the product's own words. Headings name things, buttons are verb + object, errors say what happened and how to recover. No lorem ipsum, invented testimonials, figures or logos.
- **Browser details:** focus ring, text selection, link underline offset and visible scrollbars styled from tokens: the cheapest sign a page was built, not assembled.
- **Responsive:** check 1440, 768 and 390. One column at 390, touch targets ≥ 44 px, no horizontal scroll.
- **Persuade:** the first screen says what is sold, for whom, one concrete fact and the main action (two actions at most). One idea per section. Show the real product (screens, photos) rather than abstract decoration.
- **Operate:** tables scan (aligned columns, right-aligned numbers, sticky header when long). Destructive actions confirm or undo. Everything works by keyboard.

## 3. Refuse (template tells)

Unless the brief or `design.md` asks for it:

- A page made of same-size "icon + heading + text" cards; cards inside cards.
- Eyebrow labels above headings; section numbers (01 / 02 / 03) that carry no meaning.
- The hero-metric template: a big number, a tiny label, a row of stats.
- Gradient text, glass or blur as decoration, a purple-violet gradient as the default accent.
- A thick colored `border-left` on cards or alerts; hard offset shadows (`4px 4px 0`).
- Emoji or unicode glyphs as icons. Use the project's icon library, with one stroke and weight.
- Fake content dressed as design: placeholder charts, stock photos posing as the product.
- A modal for a task that needs no interruption; monospace as a "tech" costume outside code and data.
- Light or dark chosen by category instead of where and how the screen is used.

## 4. Verify before reporting done

- Render it if you can: run the app and screenshot 1440, 768 and 390 with a headless browser that is already available. Fix everything one look shows, then look once more. Batch the fixes rather than screenshotting after every tweak.
- Can't render → review the code against the list below and write "not visually checked" in the report.

- [ ] Mode-appropriate hierarchy, one primary action per view.
- [ ] Only tokens from `design.md` (no loose hex, px font sizes or spacing).
- [ ] Contrast, focus visible, keyboard path.
- [ ] Every state: hover, disabled, loading, empty, error.
- [ ] 390 px without overflow.
- [ ] Nothing from "Refuse"; real copy, no placeholders.

## Out of scope

- Tokens and reuse of existing components → `frontend-components`.
- Component structure → `vue-atomic-design` / `react-atomic-design`.
- Defining the design system → the `design-system` agent (`workflow/design.md`).
- Load time, bundle and render cost → `performance`.
- PT-BR copy style → `content-writer-ptbr`.
