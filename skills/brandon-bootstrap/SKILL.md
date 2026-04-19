---
name: brandon-bootstrap
description: Brandon's Bootstrap implementation conventions for app UI work. Use this skill whenever writing, reviewing, or refactoring Bootstrap-based markup, Sass, or theme files; whenever the user wants layout/styling changes in a Bootstrap app; whenever you are deciding between utility classes and handwritten CSS; and whenever colors, fonts, spacing, widths, breakpoints, or component theming should propagate consistently through the app. Prefer Bootstrap utility classes for individual elements. For stylesheet-level updates, follow this strict order: existing Bootstrap Sass variables/maps, then existing Bootstrap CSS variables, then existing Bootstrap class overloads, then Bootstrap-aligned class variants, and only then standalone vanilla CSS.
license: MIT
metadata:
  author: iambrandonmcgregor
  version: "1.1"
---

# Brandon Bootstrap

Opinionated Bootstrap conventions for projects that already use Bootstrap or should clearly lean on it. The goal is to push styling decisions upward into Bootstrap's system so the UI stays consistent, reviewable, and cheap to change later.

The five topics covered here:

1. Prefer utility classes over handwritten CSS on individual elements
2. Always use Bootstrap's style system in a strict fallback order
3. Write custom Sass only when Bootstrap cannot express the job cleanly
4. Use modern CSS features that align with Bootstrap and current browser support
5. Review Bootstrap code for system drift, not just visual correctness

---

## 1. Prefer utility classes over handwritten CSS on individual elements

**The rule.** If an element can be styled cleanly with Bootstrap classes, do that instead of inventing a new Sass selector for it.

**Why.** Utility classes keep the styling decision at the call site. That makes the markup easier to scan, avoids a pile of tiny one-off selectors, and lets future edits happen without hunting through Sass partials. In Bootstrap projects, handwritten CSS should be the exception, not the first move.

**Prefer utilities for:**

- spacing: `mt-*`, `mb-*`, `px-*`, `py-*`, `gap-*`
- layout: `d-*`, `flex-*`, `justify-content-*`, `align-items-*`
- sizing: `w-*`, `h-*`, `vw-*`, `min-vw-100`
- typography: `fs-*`, `fw-*`, `lh-*`, `text-*`
- color and surfaces: `text-*`, `bg-*`, `border-*`
- rounding, shadows, positioning, overflow, and visibility helpers

### Wrong: create a class for a single element

```html
<div class="settings-header">Account settings</div>
```

```scss
.settings-header {
  margin-bottom: 1rem;
  font-size: 1.25rem;
  font-weight: 600;
}
```

### Right: express it directly in Bootstrap

```html
<div class="mb-3 fs-4 fw-semibold">Account settings</div>
```

### Right: combine utilities with a semantic component class when needed

```html
<section class="profile-card d-flex flex-column gap-3 p-4 rounded-4 shadow-sm bg-body">
  ...
</section>
```

Use the semantic class for the reusable component identity. Use utilities for the per-instance layout and spacing unless that styling truly belongs inside the component's shared contract.

---

## 2. Push thematic changes into Bootstrap Sass variables and maps

**The rule.** For style updates, always start with existing Bootstrap Sass variables/maps before touching selectors, CSS variables, or custom classes.

**Why.** Theme changes should propagate from a small number of source tokens. If brand color, font family, container width, border radius, or spacing scale changes, the right fix is almost never "patch twelve selectors." Update the Bootstrap inputs so components and utilities inherit the new design automatically.

**Reach for Bootstrap Sass configuration when changing:**

- theme colors: `$primary`, `$secondary`, `$success`, `$danger`, `$theme-colors`
- typography: `$font-family-sans-serif`, `$headings-font-family`, `$font-size-base`, heading sizes
- spacing and rhythm: `$spacer`, `$spacers`
- borders and surfaces: `$border-radius`, `$border-color`, `$box-shadow`
- layout widths: `$container-max-widths`, `$grid-breakpoints`
- generated utilities: utility maps and Bootstrap's utilities API

### Mandatory fallback order for style updates

Follow this exact order when a styling change cannot be solved with existing Bootstrap utility classes in markup:

1. Update an existing Bootstrap Sass variable/map first.
2. If no Sass variable exists for the target style but Bootstrap exposes a related CSS variable (`--bs-*`), override that CSS variable with the smallest safe selector scope.
3. If neither Sass nor CSS variables are available, overload an existing Bootstrap class that already represents that component.
4. If no suitable class exists, add a Bootstrap-aligned variant class that extends the existing component pattern (naming, spacing rhythm, state behavior).
5. Use standalone vanilla CSS only when no existing Bootstrap component or variant path can model the requirement cleanly.

Do not skip steps in this order.

### Wrong: patch the theme at the leaves

```scss
.navbar-brand,
.btn-primary,
.dashboard-link,
.welcome-banner-title {
  color: #0f766e;
}

.btn-primary {
  background-color: #0f766e;
  border-color: #0f766e;
}
```

This creates drift immediately. The next Bootstrap component you add will still use the old theme.

### Right: update the Bootstrap theme source

```scss
$primary: #0f766e;
$font-family-sans-serif: "IBM Plex Sans", system-ui, sans-serif;
$container-max-widths: (
  sm: 540px,
  md: 720px,
  lg: 960px,
  xl: 1140px,
  xxl: 1320px,
);

@import "bootstrap/scss/bootstrap";
```

### Right: extend the utility system instead of adding bespoke helpers

```scss
$utilities: map-merge(
  $utilities,
  (
    "letter-spacing": (
      property: letter-spacing,
      class: ls,
      values: (
        tight: -0.02em,
        base: 0,
        wide: 0.08em,
      ),
    ),
  )
);
```

That lets the app use utilities like `ls-wide` instead of sprinkling handwritten CSS helpers everywhere.

### Right: prefer scoped Bootstrap CSS variable overrides before class-level overrides

```scss
.billing-card {
  --bs-card-border-color: var(--bs-primary);
  --bs-card-cap-bg: color-mix(in srgb, var(--bs-primary) 8%, transparent);
}
```

This keeps the change inside Bootstrap's token system and avoids brittle property-level overrides.

---

## 3. Write custom Sass only when Bootstrap cannot express the job cleanly

**The rule.** Write custom Sass only after the fallback order above fails. Do not write Sass just because it feels tidier than a few utility classes.

**Good reasons for custom Sass:**

- a reusable component needs a stable semantic class contract
- the styling requires selectors, pseudo-elements, keyframes, or state relationships utilities cannot express well
- Bootstrap's theme variables and utility API still cannot represent the design cleanly
- you are encapsulating repeated design logic that would otherwise be duplicated in many templates

**Bad reasons for custom Sass:**

- "I only need margin, font-size, and color"
- "The class attribute looks long"
- "I can target this one element from a stylesheet instead"

### Wrong: hide simple styling in Sass

```html
<button class="marketing-cta">Start assessment</button>
```

```scss
.marketing-cta {
  display: inline-flex;
  align-items: center;
  padding: 0.75rem 1.25rem;
  border-radius: 999px;
  font-weight: 600;
}
```

### Right: keep simple presentation in the markup

```html
<button class="btn btn-primary d-inline-flex align-items-center px-4 py-3 rounded-pill fw-semibold">
  Start assessment
</button>
```

### Right: use Sass for actual component-level behavior

```scss
.timeline-step {
  position: relative;
}

.timeline-step::before {
  content: "";
  position: absolute;
  inset-block: 0;
  inset-inline-start: 1rem;
  width: 2px;
  background: var(--bs-border-color);
}
```

That is a good Sass use case because Bootstrap utilities do not express the pseudo-element behavior cleanly.

---

## 4. Use modern CSS that fits Bootstrap's philosophy

Use modern CSS when writing custom rules, but stay aligned with Bootstrap's compatibility posture and avoid novelty for novelty's sake.

Prefer:

- CSS custom properties for token propagation and local scoping
- logical properties (`margin-inline`, `padding-block`, `inset-inline-start`) for direction-aware layouts
- modern layout primitives (`gap`, flexbox, grid) where Bootstrap utilities do not already solve the need
- functions like `clamp()` and `min()`/`max()` where they improve responsiveness cleanly

Avoid:

- introducing experimental features Bootstrap does not rely on in production
- feature choices that require heavy fallback layers for the app's target evergreen browsers
- custom CSS abstractions that duplicate Bootstrap utilities without clear value

When in doubt, choose the most Bootstrap-native and broadly supported option.

---

## 5. Review Bootstrap code for system drift, not just visual correctness

When writing or reviewing Bootstrap-based UI, check these in order:

1. Could this element be styled with existing Bootstrap utilities instead of custom Sass?
2. If this needs stylesheet changes, did we try existing Bootstrap Sass variables/maps first?
3. If no Sass variable exists, did we try overriding Bootstrap's existing CSS variables with minimal selector scope?
4. If variables are not available, are we overloading an existing Bootstrap class before inventing new standalone CSS?
5. If a new class is required, does it extend an existing Bootstrap component pattern instead of creating disconnected styling?
6. Is any custom Sass doing real component work, or is it hiding spacing/typography/color choices that belong in markup or theme config?
7. Will a future brand refresh be able to change this area centrally, or did we hard-code leaf styles that will have to be hunted down later?

### Wrong: local override that fights the system

```scss
.card-title {
  font-family: "Merriweather", serif;
}

.modal-title {
  font-family: "Merriweather", serif;
}

.offcanvas-title {
  font-family: "Merriweather", serif;
}
```

### Right: make the system own the choice

```scss
$headings-font-family: "Merriweather", Georgia, serif;

@import "bootstrap/scss/bootstrap";
```

---

## Applying this skill

When editing Bootstrap projects:

1. Start by asking whether the change can be solved with existing Bootstrap classes in the markup.
2. If stylesheet changes are needed, update existing Bootstrap Sass variables/maps first.
3. If Sass variables do not exist for that concern, override existing Bootstrap CSS variables (`--bs-*`) with the narrowest selector scope that still solves the requirement.
4. If Bootstrap has no relevant Sass or CSS variable, overload an existing Bootstrap class for that component.
5. If no class exists to overload, add a Bootstrap-aligned variant class that extends an existing Bootstrap component pattern.
6. Use standalone vanilla CSS only when no Bootstrap variable, class, or component-extension route works cleanly.
7. Prefer modern CSS features supported across current evergreen browsers, and choose features Bootstrap itself treats as safe patterns.
8. Keep custom selectors focused on component structure, pseudo-elements, complex states, or behavior Bootstrap does not model well.
9. When reviewing code, flag one-off Sass that should be replaced by Bootstrap utilities, upstream variables, or Bootstrap-aligned class extensions.

If the project already has an established Bootstrap theme entrypoint or token file, make changes there rather than scattering overrides across unrelated partials.
