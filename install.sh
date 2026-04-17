#!/usr/bin/env bash
# Install every skill in this repo into ~/.agents/skills/ as a live symlink.
#
# What this does:
#   1. Runs `npx skills add . -g --all -y` once so the per-agent symlinks
#      (~/.claude/skills/<name>, ~/.cursor/skills/<name>, etc.) get created
#      pointing at ~/.agents/skills/<name>.
#   2. Replaces the hub directory at ~/.agents/skills/<name> — which by
#      default is a file-level copy — with a symlink back to the source
#      folder in this repo.
#
# After running this once, every edit you make to skills/<name>/SKILL.md in
# this repo is live in all installed agents immediately, no reinstall
# required.
#
# Safe to re-run. Skips unchanged symlinks; re-links any that drift.

set -euo pipefail

# Resolve this script's directory so the script works regardless of cwd.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"
HUB_DIR="$HOME/.agents/skills"

# Sanity: make sure the skills/ folder is where we expect.
if [ ! -d "$SKILLS_DIR" ]; then
  echo "error: expected $SKILLS_DIR to exist" >&2
  exit 1
fi

echo "== Step 1: running \`npx skills add\` to register per-agent symlinks =="
# This populates ~/.agents/skills/<name> with a copy AND symlinks every
# installed agent's own skills directory (Claude Code, Cursor, Codex, ...)
# at that hub location. We replace the copy with a symlink in step 2.
npx -y skills@latest add "$REPO_DIR" --global --all --yes

mkdir -p "$HUB_DIR"

echo
echo "== Step 2: replacing hub copies with symlinks to this repo =="
for skill_path in "$SKILLS_DIR"/*/; do
  # Trim trailing slash and derive the skill's folder name.
  skill_path="${skill_path%/}"
  name="$(basename "$skill_path")"
  target="$HUB_DIR/$name"

  # If the hub entry is already a symlink pointing at this source, skip.
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$skill_path" ]; then
    echo "  ok   $name (already linked)"
    continue
  fi

  # Remove whatever's there (copy, broken symlink, wrong symlink) and
  # replace with a symlink to the live source.
  rm -rf "$target"
  ln -s "$skill_path" "$target"
  echo "  link $name -> $skill_path"
done

echo
echo "== Step 3: cleaning up stale symlinks from renamed/removed skills =="
# Any symlink in the hub that points into this repo but to a folder that
# no longer exists (because we renamed or deleted the skill folder) is
# stale. Remove it so it stops showing up in `npx skills list`.
shopt -s nullglob
for entry in "$HUB_DIR"/*; do
  # Only act on symlinks that point inside this repo.
  if [ -L "$entry" ]; then
    dest="$(readlink "$entry")"
    case "$dest" in
      "$SKILLS_DIR"/*)
        # It's one of ours. If the target doesn't exist, clean it up.
        if [ ! -e "$dest" ]; then
          echo "  prune $(basename "$entry") (dangling -> $dest)"
          rm -f "$entry"
        fi
        ;;
    esac
  fi
done

echo
echo "Done. Edits to $SKILLS_DIR/<name>/SKILL.md are now live in every agent."
echo
echo "To verify:"
echo "  npx skills list -g"
echo "  ls -la $HUB_DIR"
