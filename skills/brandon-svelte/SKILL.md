---
name: brandon-svelte
description: Brandon's personal Svelte 5 patterns and conventions — when to use component-local `$state` versus shared stores versus Context API, when to extract state into a `.svelte.js` / `.svelte.ts` global-state file versus keeping it colocated in components, and when to prefer `async`/`await` versus raw promise chains (including when to reach for `{#await}` blocks). Use this skill whenever working in a Svelte or SvelteKit project; whenever the user mentions `$state`, `$derived`, `$effect`, `$props`, runes, stores, context, `writable`, `setContext`, `getContext`, a `.svelte.js` file, or shared state between components; whenever deciding where a piece of state should live; and whenever writing or reviewing async code in a Svelte component or load function.
license: MIT
compatibility: Targets Svelte 5+ (runes). Most guidance applies to Svelte 4 by substituting `writable` stores for runes.
metadata:
  author: iambrandonmcgregor
  version: "1.0"
---

# Svelte

Opinionated guidance for Svelte 5 projects. Covers three decisions that come up constantly:

1. **Where does this state live?** Component-local `$state`, Context API, or a shared global state file.
2. **When do I reach for a store vs a runes-based state file?**
3. **Async: `await` vs promise chains vs `{#await}`.**

The examples assume Svelte 5 runes syntax. If you're in a Svelte 4 codebase, substitute `writable()` stores for `$state` and the principles still hold.

---

## 1. State location: `$state` vs Context vs shared global file

Start at the narrowest scope. Widen only when the state is actually shared.

### Decision tree

Ask these in order — the first "yes" wins:

1. **Is this state only used inside one component?** → `$state` inside that component.
2. **Is it shared with a small subtree of components, and that subtree is logically a single feature (a form, a modal, a page layout)?** → Context API. Create and set the context in the root of the subtree.
3. **Is it shared across unrelated parts of the app, or persists across navigation, or needs to be read outside the component tree entirely (load functions, API clients)?** → Shared global state file — a `.svelte.js` or `.svelte.ts` module that exports runes-based reactive state.

### Why the order matters

Each level up trades simplicity for reach. Component-local state is the cheapest: no imports, no setup, no question about who else can mutate it. Context is mid-cost: you set it up once at the boundary, and everything inside reads transparently, but now you have a provider-consumer contract. Global state is the most expensive: any part of the app can touch it, so any bug can come from anywhere.

**A common failure mode** is reaching for a store or a global file because "it might be shared someday." It almost never is. Start local; promote only when a second real use-case appears.

### Example: component-local

```svelte
<!-- Counter.svelte -->
<script>
  // Only this component cares. $state is the right default.
  let count = $state(0);
</script>

<button onclick={() => count++}>{count}</button>
```

### Example: context for a subtree

When a form, modal, or feature has several nested components that all need to read or mutate the same state, use Context. You set the context in the root of the feature and read it in descendants — no prop drilling, no global state.

```svelte
<!-- routes/checkout/+page.svelte -->
<script>
  import { setContext } from 'svelte';
  import CheckoutSteps from './CheckoutSteps.svelte';

  // Create a reactive state object and hand it to context. Descendants
  // can read and mutate it without prop drilling.
  const checkout = $state({
    step: 1,
    shipping: null,
    payment: null,
  });

  // Use a Symbol as the key to avoid accidental collisions with other
  // contexts (strings are fine too but Symbols can't be typo'd).
  setContext('checkout', checkout);
</script>

<CheckoutSteps />
```

```svelte
<!-- routes/checkout/ShippingForm.svelte -->
<script>
  import { getContext } from 'svelte';

  // Same reference as the one set above. Mutations propagate because
  // it's a rune-backed object.
  const checkout = getContext('checkout');
</script>

<input bind:value={checkout.shipping} />
<button onclick={() => checkout.step = 2}>Continue</button>
```

**Why context over a store here?** The checkout state is scoped to the checkout flow — it shouldn't leak into the rest of the app. Context gives us exactly that scoping for free: when the user navigates away, the subtree unmounts and the state is garbage-collected. A global store would persist, and we'd have to remember to reset it.

### Example: shared global state file

When state is legitimately app-wide — current user, theme, notification queue, feature flags — extract it into a `.svelte.js` or `.svelte.ts` file. With Svelte 5, these files can use runes directly; no stores needed.

```js
// src/lib/state/auth.svelte.js

// The exported object is reactive. Components that import it and read
// its fields will re-render when those fields change — same as reading
// $state inside a component.
export const auth = $state({
  user: null,
  isLoading: true,
});

// Co-located mutators keep the API discoverable. Everything that
// touches auth.user lives in one file.
export async function signIn(credentials) {
  auth.isLoading = true;
  try {
    // Attempt the login. Annotate errors so callers can tell shipping
    // problems apart from credential problems.
    const user = await api.login(credentials);
    auth.user = user;
    return user;
  } finally {
    auth.isLoading = false;
  }
}

export function signOut() {
  auth.user = null;
}
```

```svelte
<!-- Any component anywhere -->
<script>
  import { auth, signOut } from '$lib/state/auth.svelte.js';
</script>

{#if auth.user}
  <p>Signed in as {auth.user.name}</p>
  <button onclick={signOut}>Sign out</button>
{/if}
```

**Why `.svelte.js` and not `.js`?** Runes are only compiled inside files with the `.svelte` extension or `.svelte.js` / `.svelte.ts`. A plain `.js` file cannot use `$state`. If you forget this, you'll get confusing "runes are not allowed" compiler errors.

### Wrong: using context for truly global state

```svelte
<!-- +layout.svelte -->
<script>
  import { setContext } from 'svelte';

  // This context is set at the root and read deep in every page.
  // There's no benefit to the subtree scoping — it's effectively
  // global. Just use a shared .svelte.js file.
  setContext('auth', $state({ user: null }));
</script>
```

### Wrong: using a global file for state that only one component uses

```js
// src/lib/state/counter.svelte.js — overkill if only Counter.svelte uses it
export const counter = $state({ value: 0 });
```

Keep it local until it isn't.

---

## 2. Stores vs `.svelte.js` runes files

Svelte 4's `writable`/`readable`/`derived` stores still work in Svelte 5, and they remain the right answer in two cases. Otherwise, prefer a `.svelte.js` file with runes.

### When stores are still the right tool

- **Interop with code that expects the `subscribe` protocol.** Some libraries, Svelte transitions, and third-party utilities consume stores via `$store` auto-subscription. If you're writing something those need to consume, ship a store.
- **You're on Svelte 4**, or you're adding a small feature to a Svelte 4 codebase and don't want to mix idioms.

### When to prefer `.svelte.js`

- You're on Svelte 5, writing new code, and you control the consumers.
- The state is plain reactive data (objects, arrays, primitives) with some mutator functions.
- You want the mutators and state colocated in one file with no `.subscribe` / `set` / `update` ceremony.

### Why

Runes-based state files are simpler: you import the object and read its fields the same way you would any reactive state. No `$`-prefix auto-subscription, no `get()` calls outside components, no separate writable-vs-readable API. For *new* code in Svelte 5, the ceremony of stores rarely pays off — and mixing runes for local state with stores for shared state is inconsistent.

### Right: runes-based shared state

```js
// src/lib/state/notifications.svelte.js
export const notifications = $state([]);

export function notify(message, level = 'info') {
  // Push the notification and schedule its dismissal.
  const id = crypto.randomUUID();
  notifications.push({ id, message, level });
  setTimeout(() => dismiss(id), 5000);
}

export function dismiss(id) {
  const i = notifications.findIndex((n) => n.id === id);
  if (i !== -1) notifications.splice(i, 1);
}
```

### Right: a store, when you need the `subscribe` protocol

```js
// src/lib/stores/route-history.js
import { writable } from 'svelte/store';

// Exported as a store because a vendor analytics library we use expects
// `subscribe()`. Otherwise this would be a .svelte.js file.
export const routeHistory = writable([]);
```

---

## 3. async/await vs promise chains vs `{#await}`

Three tools, three jobs.

### `async`/`await`: the default for procedural async code

If the async flow is essentially linear — do this, then do that, then do the next thing — use `await`. It reads like synchronous code, makes stack traces readable, and plays nicely with `try/catch`.

```js
async function loadUserDashboard(userId) {
  // Pull the user first; everything else depends on it.
  const user = await api.getUser(userId);

  // Once we have the user, the next two fetches are independent of
  // each other — fire them in parallel and await both.
  const [orders, messages] = await Promise.all([
    api.getOrders(user.id),
    api.getMessages(user.id),
  ]);

  return { user, orders, messages };
}
```

### Promise chains: when the flow is a pipeline, not a procedure

Reach for `.then()` only when:

- You're transforming a promise into another promise and passing it along (e.g., from an event handler to something that takes a promise).
- You need `Promise.all`, `Promise.race`, or similar as part of a larger expression.
- Inside `.catch` handlers at the top of an app where no surrounding `async` function exists.

### Wrong: mixing promise chains with async/await

```js
async function loadThing(id) {
  // Gratuitous .then inside an async function. Just await it.
  return api.get(id).then((data) => ({ ...data, loadedAt: Date.now() }));
}
```

### Right: straight await

```js
async function loadThing(id) {
  const data = await api.get(id);
  return { ...data, loadedAt: Date.now() };
}
```

### Wrong: serial awaits that should be parallel

```js
async function loadPage() {
  // These fetches don't depend on each other. Doing them in series
  // doubles the wait time for no reason.
  const user = await api.getUser();
  const config = await api.getConfig();
  return { user, config };
}
```

### Right: parallel with `Promise.all`

```js
async function loadPage() {
  const [user, config] = await Promise.all([api.getUser(), api.getConfig()]);
  return { user, config };
}
```

### `{#await}`: the templating default

Inside `.svelte` files, prefer the `{#await}` block over `$state` loading flags when you're rendering something that depends on a promise. The template block handles the pending, resolved, and rejected branches declaratively — no `isLoading`, no `error` variable to keep in sync, no `$effect` to manage.

### Wrong: hand-rolled loading state

```svelte
<script>
  let user = $state(null);
  let isLoading = $state(true);
  let error = $state(null);

  // Three pieces of state to keep in sync, easy to get wrong on refetch.
  $effect(async () => {
    try {
      user = await api.getUser();
    } catch (err) {
      error = err;
    } finally {
      isLoading = false;
    }
  });
</script>

{#if isLoading}
  Loading…
{:else if error}
  Error: {error.message}
{:else}
  <p>{user.name}</p>
{/if}
```

### Right: `{#await}` block

```svelte
<script>
  // Just a promise. No loading flags, no effect, no catch-and-rethrow.
  let userPromise = $state(api.getUser());

  // Refetch by reassigning.
  function refresh() {
    userPromise = api.getUser();
  }
</script>

{#await userPromise}
  Loading…
{:then user}
  <p>{user.name}</p>
{:catch err}
  Error: {err.message}
{/await}

<button onclick={refresh}>Refresh</button>
```

### When to deviate

If you need to react to the resolved value (trigger a follow-up, log analytics, mutate other state), an `$effect` with `await` is often clearer than `{#await}`. Pick whichever makes the flow read top-to-bottom.

---

## Applying this skill

When writing a new piece of state:

1. Put it inside the component as `$state`.
2. If a second component needs the same instance, ask: is it a subtree (feature) or the whole app?
3. For a subtree → Context. For the whole app → `.svelte.js` file with runes.
4. Only use stores if you're on Svelte 4 or need the `subscribe` protocol for interop.

When writing async code:

1. Default to `async`/`await`.
2. Wrap independent fetches in `Promise.all` so they run in parallel.
3. For rendering data from a promise in a template, use `{#await}` unless you also need to react to the resolved value.

When reviewing:

- Flag global state files that only have one consumer — pull them back into the component.
- Flag context usage that never narrows below the layout root — make it a `.svelte.js` file instead.
- Flag serial awaits that should be `Promise.all`.
- Flag hand-rolled loading/error flags in templates where `{#await}` would do.
