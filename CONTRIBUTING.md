# Contributing / authoring notes

These are notes-to-self on how to keep this repo tidy as it grows.

## Skill naming rules

The `name` in YAML frontmatter must match the directory name exactly, and both must match the regex `^[a-z0-9]+(-[a-z0-9]+)*$`. That is:

- all lowercase
- numbers allowed
- single hyphens between words (no double hyphens, no leading or trailing hyphens)

Good: `web-dev-baseline`, `svelte`, `api-design`, `git-workflow`

Bad: `WebDev`, `web_dev`, `web--dev`, `-svelte`

## Frontmatter checklist

Every `SKILL.md` must open with a YAML block containing at minimum:

```yaml
---
name: the-skill-name
description: One or two sentences describing what this skill does AND when it should trigger. This is what the agent reads to decide whether to invoke the skill.
---
```

Optional fields worth knowing:

- `license: MIT` — lets consumers know the terms.
- `compatibility: ...` — human-readable notes about environment requirements, e.g. `"Requires Node 20+"`.
- `metadata: { author: brandonmcgregor, version: "1.0" }` — arbitrary string/string map. Setting `metadata.internal: true` hides the skill from `npx skills` discovery (useful for drafts).
- `allowed-tools: Read, Grep, Bash(npm:*)` — signals which tools the skill actually uses. Helps users evaluate trust.

## Description-writing tips

The `description` field is the single most important sentence in the whole skill — it's what determines whether the agent pulls the skill into context. Two rules:

1. State *what* the skill does in concrete terms.
2. List *when* it should trigger. Include the kinds of phrases a user might actually say (e.g., "when working on Svelte components or hearing 'runes', '$state', '$derived', 'store'").

Keep it under ~1024 chars but don't cut it so short that triggers get missed.

## Body-length discipline

Aim for SKILL.md bodies under ~500 lines. If a skill needs more, split long domain knowledge into `references/<topic>.md` and have the skill body tell the agent when to load it. This keeps context usage proportional to the task, not the size of the skill.

## Updating the README table

Every new skill must be added to the Available skills table in the root [README.md](./README.md). This is what renders on skills.sh and is what a human browsing the repo on GitHub sees first.
