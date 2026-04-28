---
name: brandon-git
description: Brandon's Git writing conventions for imperative commit messages, PR titles, changelog entries derived from commits, and commit or PR suggestions. Use this skill whenever writing, reviewing, rewriting, or suggesting Git commit messages, GitHub pull request titles, changelog or release-note entries based on commits, merge/squash commit text, or version-control history summaries.
license: MIT
metadata:
  author: iambrandonmcgregor
  version: "1.0"
---

# Brandon Git

Use imperative mood for every generated commit subject, PR title, changelog entry derived from commits, and commit or PR suggestion. These strings should read like commands that say what applying the change will do.

## Imperative subject checklist

Before creating or suggesting a commit message, PR title, or commit-derived changelog entry, verify the subject line against this checklist:

1. It passes this sentence test: `If applied, this commit will <subject>`.
2. It starts with a capitalized imperative verb such as `Add`, `Fix`, `Remove`, `Refactor`, `Update`, `Rename`, `Document`, or `Test`.
3. It avoids past tense, gerunds, and vague non-command phrasing; see the bad examples below.
4. It does not end with a period.
5. It is around 50 characters when practical, while staying specific enough to be useful.

If the first draft fails any item, rewrite it until it satisfies the checklist before creating the commit or PR.

## Commit message bodies

Use a body only when the subject cannot carry the useful context on its own.

- Separate the subject from the body with a blank line.
- Explain what changed and why the change matters.
- Do not use the body merely to restate how the code changed; the diff already shows that.

## Reviews and suggestions

When reviewing existing commits or PRs, flag non-imperative subjects and suggest corrected versions. Focus on the subject line first because it is reused in logs, squash commits, release notes, and changelogs.

## Examples

### Commit subject

Bad: `Added payment webhook validation`

Good: `Add payment webhook validation`

Bad: `Fixed login redirect bug`

Good: `Fix login redirect after OAuth callback`

### Documentation update

Bad: `Updating Bootstrap skill docs`

Good: `Update Bootstrap skill documentation`

### Changelog entry derived from a commit

Bad: `Changes for release notes`

Good: `Document release note generation rules`

Bad: `Misc fixes`

Good: `Fix profile settings validation`

### Commit with body

```text
Refactor skill install setup

Keep the registration step separate from live symlink replacement so
future skill additions can reuse the same install flow without manually
repairing agent-specific skill directories.
```
