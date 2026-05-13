---
name: brandon-git
description: Brandon's Git conventions for immutable history plus imperative commit messages, PR titles, changelog entries derived from commits, and commit or PR suggestions. Use this skill whenever writing, reviewing, rewriting, or suggesting Git commit messages, GitHub pull request titles, changelog or release-note entries based on commits, merge/squash commit text, version-control history summaries, or any operation that could revise committed Git history.
license: MIT
metadata:
  author: iambrandonmcgregor
  version: "1.1"
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

## Treat Git history as immutable

Consider written Git history immutable. Do not revise existing commits, branch history, or published refs unless the user explicitly asks for a history rewrite.

History-rewriting operations include `git commit --amend`, interactive or non-fast-forward rebases, squash/fixup rewrites, `git reset` that moves a branch to change committed history, `git filter-branch`, `git filter-repo`, `git push --force`, and equivalent tooling.

When the user explicitly asks for one of these operations:

1. State that it rewrites Git history.
2. Name the branch, commit range, or ref that will be affected.
3. Ask for confirmation before executing when a user prompt is available.

Prefer additive fixes such as a new commit or `git revert` when the goal can be achieved without rewriting history.

## Commit message bodies

Use a body only when the subject cannot carry the useful context on its own.

- Separate the subject from the body with a blank line.
- Explain what changed and why the change matters.
- Do not use the body merely to restate how the code changed; the diff already shows that.

## Commit attribution policy

When creating commits as an agent, do not credit the agent in commit metadata.

- Do not add `Co-authored-by` trailers for the agent.
- Do not add `Signed-off-by` or custom trailers that identify the agent.
- Do not add agent attribution in the commit subject or body.

Commit authorship should reflect only the user/repository's normal Git identity configuration unless the user explicitly requests a specific attribution format.

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
