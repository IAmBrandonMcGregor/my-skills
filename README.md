# Brandon's Skills

A personal collection of [Agent Skills](https://skills.sh/) for AI-assisted development — opinionated guidance, conventions, and workflows I want my AI tools to follow across my projects.

## Available skills

All skills in this repo are prefixed with `brandon-` so they won't collide with community skills of the same unqualified name (`svelte`, `web-dev-baseline`, etc.) in the `~/.agents/skills/` namespace.

| Skill | Description |
|-------|-------------|
| [`brandon-web-dev-baseline`](./skills/brandon-web-dev-baseline) | Baseline code-quality guidance for JS, HTML, CSS, Svelte — function sizing, comment density, naming conventions, error handling. |
| [`brandon-svelte`](./skills/brandon-svelte) | Svelte-specific patterns: when to use context vs `$state` vs stores, global state vs component state, async/await vs promises. |

## Install

All of these skills are installable with the open [`npx skills`](https://github.com/vercel-labs/skills) CLI. The repo is public on GitHub but not published to npm — the CLI installs directly from the git repo.

Install a single skill:

```bash
npx skills add iambrandonmcgregor/my-skills --skill brandon-web-dev-baseline
```

Install every skill in this repo:

```bash
npx skills add iambrandonmcgregor/my-skills
```

List what's available without installing:

```bash
npx skills add iambrandonmcgregor/my-skills --list
```

Skills install into the current project (check with `npx skills list`) and are picked up automatically by any agent that reads the open Agent Skills spec — Claude Code, Codex, Cursor, OpenCode, and others.

### Live-edit setup (for my own machine)

`npx skills add` copies the skill files into `~/.agents/skills/<name>/`, so edits to this repo don't propagate by default. To make edits instantly live in every installed agent:

```bash
bash ~/Documents/projects/my-skills/install.sh
```

That script registers the skills with every agent (via `npx skills add`) and then replaces the hub copy at `~/.agents/skills/<name>/` with a symlink back to this repo. After running it once, editing any `SKILL.md` here is immediately live — no reinstall needed. The script is idempotent; safe to re-run whenever a new skill folder is added.

## Repository layout

```
my-skills/
├── README.md                 # this file — the skills.sh-facing summary
├── CONTRIBUTING.md
├── install.sh                # one-shot setup for live-edit symlinks
├── LICENSE
├── .gitignore
└── skills/
    ├── brandon-web-dev-baseline/
    │   └── SKILL.md          # YAML frontmatter + markdown body
    └── brandon-svelte/
        └── SKILL.md
```

Each skill is a single folder containing a `SKILL.md`. Optional subfolders (`scripts/`, `references/`, `assets/`) can be added to any skill if it needs bundled helpers; the content loads on-demand so the agent's context stays lean.

## Authoring new skills

1. Create a new folder under `skills/` named with lowercase letters, numbers, and single hyphens (must match the `name` field in frontmatter).
2. Add a `SKILL.md` with YAML frontmatter (`name` and `description` are required; `license`, `compatibility`, `metadata`, and `allowed-tools` are optional).
3. Keep the body under ~500 lines; push long reference material into a `references/` subfolder and link to it.
4. Add the skill to the table at the top of this README.

See the [Vercel Agent Skills guide](https://vercel.com/kb/guide/agent-skills-creating-installing-and-sharing-reusable-agent-context) for the full spec.

## License

MIT — see [LICENSE](./LICENSE). Feel free to copy, fork, or remix any of these skills.
