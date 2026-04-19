---
name: brandon-web-dev-baseline
description: Brandon's personal baseline code-quality conventions for any web development work — JavaScript, TypeScript, HTML, CSS, or Svelte. Covers function sizing (inverse relationship between length and call-site count), liberal inline commenting of logic sections, predictable top-of-file structure for modules and Svelte component scripts, naming conventions for variables/files/CSS classes, and error-handling philosophy. Use this skill whenever writing, reviewing, or refactoring code in a web project; whenever deciding whether to extract a helper or inline something; whenever organizing imports, props, state, or section comments in a component/module; whenever choosing variable, file, or class names; and whenever a `try/catch`, `throw`, or promise rejection is involved. Also apply when the user mentions "clean up", "refactor", "split this up", or asks for a code review on web code.
license: MIT
metadata:
  author: iambrandonmcgregor
  version: "1.1"
---

# Web dev baseline

Opinionated code-quality conventions that apply to every web project I work on. Follow these whenever writing or editing JavaScript, TypeScript, HTML, CSS, or Svelte — and for other languages, treat them as sensible defaults unless something else overrides.

The five topics covered here:

1. Function sizing
2. Inline comments on logic sections
3. Top-of-file structure for modules and component scripts
4. Naming conventions
5. Error handling

Each section states the rule, explains *why* it matters, then shows concrete right/wrong examples. The examples are the most important part — prefer pattern-matching the examples over parsing the prose.

---

## 1. Function sizing: length is inversely related to reuse

**The rule.** A function's ideal length is inversely proportional to how often it's called.

- A function called in one place should generally stay inline, even if it grows to 30, 50, or 80 lines, if extracting it would not meaningfully improve readability or reuse.
- A function called from many places can and should be kept tight — 3 to 10 lines — so each caller absorbs it cheaply.
- Do not extract a 3-line helper that is called from exactly one place. That's abstraction for its own sake and costs more than it saves.

**Why.** Abstractions have a tax: readers have to jump to the definition, carry a mental model of the helper's contract, and worry about whether behavior is safe to change. That tax is worth paying when many callers share the helper — the savings compound. It is **not** worth paying for a one-off. Inlined code lets the reader see exactly what happens in the function they're already reading, with no indirection.

The mirror point: a tight, well-named 4-line function used in twenty places pays for itself twenty times over. Keep those short, because every extra line there is paid for twenty times.

**Rules of thumb for deciding.**

- Used once, < ~50 lines, doesn't need a name to explain it → inline.
- Used once, but the extraction dramatically clarifies the outer function (e.g., naming a gnarly condition) → extract, but keep the name crisp.
- Used in 3+ places → extract. Prefer tight and well-named over clever.
- Used in 10+ places → treat it as a primitive. Short, stable signature, high test coverage.

### Wrong: one-shot extraction that adds noise

```js
// The helper is called exactly once. Pulling it out adds indirection
// without clarifying anything — the reader now has to scroll to see
// what `buildGreeting` actually does.
function buildGreeting(name) {
  return `Hello, ${name}!`;
}

function renderHeader(user) {
  const greeting = buildGreeting(user.name);
  document.querySelector('#header').textContent = greeting;
}
```

### Right: inline the one-off

```js
function renderHeader(user) {
  // Inline — the greeting is trivial and used nowhere else, so it lives
  // where the reader is already looking.
  document.querySelector('#header').textContent = `Hello, ${user.name}!`;
}
```

### Wrong: sprawling shared helper

```js
// Called from 15 places. Every caller pays this cost on every read.
function formatPrice(cents, opts) {
  if (opts && opts.currency) {
    if (opts.currency === 'USD') {
      const dollars = cents / 100;
      const formatted = dollars.toFixed(2);
      // ...20 more lines of branching...
    }
  }
}
```

### Right: a tight primitive used many times

```js
// Short, stable, one job. Cheap for every caller.
function formatUSD(cents) {
  return `$${(cents / 100).toFixed(2)}`;
}
```

### Right: a legitimately long one-off

```js
// Setup for a component mount that happens exactly once on app boot.
// It's long because the work is genuinely linear — extracting sub-steps
// into tiny helpers would scatter a readable narrative across four
// files. Readers can scan top-to-bottom in one place.
function bootstrapApp() {
  // Read config from the DOM-injected script tag.
  const configEl = document.querySelector('#app-config');
  const config = JSON.parse(configEl.textContent);

  // Wire up global error reporting before anything else so early
  // failures during setup get captured.
  window.addEventListener('error', (e) => reportError(e.error, config.env));
  window.addEventListener('unhandledrejection', (e) => reportError(e.reason, config.env));

  // Hydrate the auth state from the cookie.
  const authToken = document.cookie.split('; ').find((c) => c.startsWith('token='))?.slice(6);
  const user = authToken ? decodeJwt(authToken) : null;

  // Mount the root component.
  const root = document.querySelector('#app');
  mount(App, { target: root, props: { user, config } });
}
```

---

## 2. Inline comments on every logic section

**The rule.** Every non-trivial logic section in a function gets a short comment explaining *what is happening* and, where useful, *why*. Not every line — that's noise. Every **section**, where a section is a paragraph of related statements.

**Why.** Code expresses the mechanism; comments express the intent. A reader (future-me, a teammate, an AI agent) can parse mechanism from the code, but intent has to come from somewhere — the commit message is too far away and the code itself can't say why this approach was chosen over others. Liberal commenting also makes diffs more reviewable, because reviewers can read the comments and see whether the code matches the stated intent.

**Good comments answer at least one of:**

- What is this block trying to accomplish?
- Why this approach instead of an obvious alternative?
- What gotcha or invariant must the reader know?

**Avoid:**

- Restating the code literally (`// increment i`).
- Comments that will go stale (`// TODO: currently only handles 3 cases` — write that as a test or a `throw` instead).
- Block comments that describe five lines down the file.

### Wrong: code with no narrative

```js
function applyDiscount(cart, code) {
  const rule = rules.find((r) => r.code === code);
  if (!rule) return cart;
  if (rule.expiresAt < Date.now()) return cart;
  const eligible = cart.items.filter((i) => !i.onSale);
  const subtotal = eligible.reduce((s, i) => s + i.price, 0);
  return { ...cart, discount: Math.round(subtotal * rule.percent) };
}
```

A reader has to re-derive the business logic from the mechanics.

### Right: same code, sections labeled

```js
function applyDiscount(cart, code) {
  // Look up the rule. Unknown codes are a no-op rather than an error —
  // we don't want a typo in a URL to block checkout.
  const rule = rules.find((r) => r.code === code);
  if (!rule) return cart;

  // Expired codes are also a silent no-op. Auditing happens upstream
  // when the code is issued, so we don't need to surface the reason here.
  if (rule.expiresAt < Date.now()) return cart;

  // Discounts never stack with items already marked on sale — that's
  // the merchandising rule the team agreed on in the 2026 pricing doc.
  const eligible = cart.items.filter((i) => !i.onSale);
  const subtotal = eligible.reduce((s, i) => s + i.price, 0);

  // Store the discount as cents (rounded) so downstream totals stay
  // integer-safe.
  return { ...cart, discount: Math.round(subtotal * rule.percent) };
}
```

### Wrong: over-commenting trivial lines

```js
// Set user name to the input value
user.name = input.value;
// Increment the counter
count++;
```

### Right: comment the section, not each line

```js
// Pull the latest form values into the user draft. The counter tracks
// how many times the user has edited before saving — we use it in
// telemetry to flag confusing forms.
user.name = input.value;
count++;
```

---

## 3. Top-of-file structure for modules and component scripts

**The rule.** Give component scripts and standalone modules a readable top-to-bottom narrative. Start with a dedicated import section, then group the rest of the file into clearly labeled sections. In Svelte, the `Component Props` section comes immediately after the import/env block.

**Why.** Most web files are read linearly. A predictable structure reduces scan time, makes reviews faster, and gives both humans and AI agents a stable place to look for props, state, handlers, derived values, and setup logic. The goal is not ceremony for its own sake; it is to make the file easy to skim and safe to edit.

**Use this structure by default.**

- Start the file with `// Include our external dependencies`, followed immediately by the import block.
- Keep import-like env dependencies in that same opening block. Do not scatter imports or env setup deeper in the file unless the framework requires it.
- In Svelte, place the `// Component Props` section immediately after the imports/env block.
- After that, organize the rest of the file into logical sections such as local state, effects/setup, event handlers, derived data, configuration, or exports.
- Small sections can use a normal `// Section Name` comment.
- Larger sections should use a header comment followed by a dashed divider line so the section break is visually obvious.

### Right: predictable Svelte component structure

```svelte
<script lang="ts">
  // Include our external dependencies
  import { setContext } from "svelte";
  import { url } from "mcgregor-utils";
  import Logo from "brand/assets/logo.png";
  import UserDropdownMenu from "../atoms/user-dropdown-menu.svelte";

  // Component Props
  let {
    children = () => {},
    selectedScan = null,
  } = $props();

  // Menu Expansion
  let isMenuExpanded = $state(false);

  function closeMenu() {
    isMenuExpanded = false;
  }

  // Scroll Reset after inner page navigation
  // - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - - |
  let doesScrollResetOnNav = $state(true);
  let pageSectionEl: HTMLElement;

  url.subscribe(resetScroll);

  function resetScroll(force: any = false) {
    if (!pageSectionEl) return;
    if (force === true || doesScrollResetOnNav) {
      pageSectionEl.scrollTo({ top: 0, behavior: "instant" });
    }
  }

  setContext("resetScroll", () => resetScroll(true));

  // Page & Nav Descriptions
  // - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - - |
  const navEntries = [
    { hed: "Journal", segments: ["journal"] },
    { hed: "Compare", segments: ["compare"] },
  ];
</script>
```

### Wrong: mixed concerns and unlabeled sections

```ts
const navEntries = buildNavEntries();

import { url } from "mcgregor-utils";

let doesScrollResetOnNav = true;
let selectedScan = null;

export function resetScroll() {
  // ...
}
```

This is harder to scan because the imports are not at the top, props/state/setup are interleaved, and the reader has to infer the structure from raw mechanics.

### Notes

- The exact section names can vary. Prefer comments that name the job of the section in plain English.
- Do not add decorative headers to tiny files that only contain one obvious block of code. The structure should help readability, not overwhelm it.
- If a section spans more than a small handful of lines or contains multiple related concepts, prefer the dashed divider style.

---

## 4. Naming conventions

### Variables and functions (JS/TS)

- `camelCase` for variables and functions: `userName`, `fetchInvoices`.
- `PascalCase` for classes, Svelte components, and type/interface names: `UserProfile`, `InvoiceRow`.
- `SCREAMING_SNAKE_CASE` for compile-time constants that represent immutable configuration: `MAX_RETRIES`, `API_BASE`. Do **not** use this for values that happen to be `const` but represent runtime state.
- Booleans start with `is`, `has`, `can`, `should`: `isVisible`, `hasDiscount`, `canEdit`.
- Async functions and values that return promises should read like an action: `loadUser`, `fetchInvoices`, not `user`/`invoices` (those read as already-resolved values).

**Why.** Consistent casing lets the reader infer what kind of thing a name refers to without reading further. `UserProfile` is clearly a type or component; `userProfile` is a value. Boolean prefixes eliminate the is-this-a-boolean-or-a-getter guessing game.

### Files

- `kebab-case.js` / `kebab-case.ts` for JS/TS modules that export functions or values: `format-price.ts`, `use-auth.js`.
- `PascalCase.svelte` for Svelte components: `UserProfile.svelte`, `InvoiceRow.svelte`.
- `kebab-case.css` for stylesheets: `button.css`, `layout.css`.
- `kebab-case.html` for HTML files: `landing.html`.
- One default export per file when practical; named exports otherwise. If a file has a single logical thing, its filename should match that thing.

**Why.** kebab-case avoids case-sensitivity bugs across filesystems (Linux is case-sensitive, macOS and Windows often are not — `UserProfile.ts` and `userprofile.ts` are the same file on macOS and different on Linux, which breaks deploys in nasty ways). The exception is Svelte components, where `PascalCase` is the community standard and matches the JSX-like usage pattern.

### CSS classes

- `kebab-case` for class names: `.user-card`, `.btn-primary`.
- Prefer a light BEM-style structure for components that have internal parts: `.user-card`, `.user-card__avatar`, `.user-card--featured`. Don't enforce BEM on simple utility classes — just use it where a component has more than 2-3 parts.
- Utility-first classes (Tailwind-style) are fine and often preferred; if mixing utility with component classes, keep component classes readable and use utilities for the tweaks.

**Why.** kebab-case is the HTML/CSS native casing — attribute selectors, CSS variables, and `data-*` attributes all use it. Mixing casings inside CSS leads to the same case-sensitivity deploy bugs as file naming.

### Wrong

```js
// Inconsistent casing, unclear boolean, typed constant used for runtime state
const USER_name = 'ada';
const visible = true;
const CURRENT_USER = fetchUser();  // misleading — this is runtime state
```

### Right

```js
const userName = 'ada';
const isVisible = true;
const currentUser = await fetchUser();
const MAX_RETRIES = 3;  // true constant, set at module load
```

### Wrong (filenames)

```
src/
  userProfile.ts
  InvoiceRow.js
  button_primary.css
```

### Right

```
src/
  user-profile.ts
  UserProfile.svelte
  button-primary.css
```

---

## 5. Error handling philosophy

**The rule.** Handle errors where you have the information to decide what to do. Let them propagate otherwise. Never swallow an error silently.

The three reasonable things to do with an error:

1. **Recover.** You know how to continue — return a default, retry, fall back. Log that you did so if the recovery is non-obvious.
2. **Annotate and rethrow.** You know context the caller doesn't (which user, which record, which step), but you don't know how to recover. Wrap the error with that context and rethrow.
3. **Let it propagate.** You don't know anything useful to add. Don't wrap it, don't log it redundantly — the handler higher up will do that.

**Why.** Logging-and-rethrowing without adding information produces duplicate logs and loses the original stack trace. Catching-and-ignoring hides bugs. The call site closest to the decision ("can we recover?") is usually the only place that has the information to make that decision correctly.

### Wrong: swallow the error

```js
async function loadInvoices() {
  try {
    return await api.getInvoices();
  } catch (err) {
    // This is the bug — the caller now thinks there are zero invoices
    // when actually the network is down.
    return [];
  }
}
```

### Right: annotate and rethrow when you have context the caller doesn't

```js
async function loadInvoicesForUser(userId) {
  try {
    return await api.getInvoices(userId);
  } catch (err) {
    // Wrap so the caller's log has the user context. `cause` preserves
    // the original stack; handlers up the chain can still reach it.
    throw new Error(`Failed to load invoices for user ${userId}`, { cause: err });
  }
}
```

### Right: recover when you genuinely know how to

```js
async function getUserAvatar(userId) {
  try {
    return await api.getAvatar(userId);
  } catch (err) {
    // The user might not have uploaded one yet — that's the 404 case
    // and it's expected. Any other status is a real failure.
    if (err.status === 404) return DEFAULT_AVATAR_URL;
    throw err;
  }
}
```

### Right: let it propagate when you can't add anything

```js
// This function has no context beyond what the caller gave it. There's
// nothing to annotate, nothing to recover. Don't wrap it in a try/catch
// just to re-throw — that only loses the stack.
async function fetchJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
  return res.json();
}
```

### On `throw` vs return-a-failure

Prefer `throw` for **exceptional** conditions (network down, invariant violated, programmer error). Prefer returning a result type or `{ ok, value, error }` shape for **expected** outcomes (form validation failed, item not found). The test: if a reasonable caller might want to *handle* this case without a `try/catch`, make it a return value.

### On promise rejections in top-level code

Any async function that is called without an `await` or `.catch` will produce an unhandled rejection and may crash the process or silently drop the error. Either `await` it, chain a `.catch`, or register a global handler. Never start a promise with no plan for its rejection path.

---

## Applying this skill

When editing or writing code:

1. Before writing a new function, ask: how many places will call this? If the answer is "one, probably forever", inline it unless it meaningfully clarifies the caller.
2. As you write each logical section (3-10 lines of related work), lead it with a short comment naming the intent.
3. For component scripts and standalone modules, structure the top of the file intentionally: imports first under `// Include our external dependencies`, then `Component Props` immediately after the import/env block in Svelte, then the remaining sections in a clear narrative order.
4. When choosing a name, match the casing convention for that kind of thing (variable, file, class, component).
5. When adding a `try/catch`, decide which of the three actions applies before writing the catch body. If the answer is "none of them", delete the `try/catch`.

When reviewing code:

- Flag single-use helpers that don't clarify anything.
- Flag logic sections with no comment.
- Flag component scripts or modules whose imports, props, state, and setup are mixed together without clear sectioning.
- Flag silent-catch blocks and unhandled promise rejections.
- Flag casing mismatches against the conventions above.
