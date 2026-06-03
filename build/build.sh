#!/usr/bin/env bash
# build.sh — regenerate both platform plugins from the single canonical source.
#
#   src/skills/        canonical, platform-neutral skills (single source of truth)
#   platform/claude/   claude-only frontmatter values + plugin.json + docs
#   platform/codex/    codex-only openai.yaml + plugin.json + docs
#   claude/            generated Claude plugin   (committed; Claude installs this)
#   codex/plugin/      generated Codex plugin    (committed; Codex installs this)
#
# Root marketplace manifests (.claude-plugin/marketplace.json, .agents/plugins/
# marketplace.json) are committed repo files, not build outputs.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/src/skills"
PLAT="$ROOT/platform"

# Per-skill allowed-tools for the Claude build (set/go add Agent). bash 3.2 — no assoc arrays.
claude_tools() {
  case "$1" in
    ready) echo "Read, Edit, Write, Bash, Grep, Glob, AskUserQuestion" ;;
    set|go) echo "Read, Edit, Write, Bash, Grep, Glob, Agent, AskUserQuestion" ;;
  esac
}

# ── Claude → ./claude ───────────────────────────────────────────────────────
echo "=== build: claude ==="
rm -rf "$ROOT/claude"
mkdir -p "$ROOT/claude/.claude-plugin"
cp -R "$SRC" "$ROOT/claude/skills"
for s in ready set go; do
  INJECT=$'disable-model-invocation: true\nallowed-tools: '"$(claude_tools "$s")" \
    perl -0777 -i -pe 'BEGIN{$j=$ENV{INJECT}} s/\A(---\n.*?\n)---\n/$1$j\n---\n/s' \
    "$ROOT/claude/skills/$s/SKILL.md"
done
cp "$PLAT/claude/plugin.json" "$ROOT/claude/.claude-plugin/plugin.json"
cp "$PLAT/claude/README.md" "$PLAT/claude/README_KO.md" "$PLAT/claude/LICENSE" "$ROOT/claude/"

# ── Codex → ./codex/plugin ──────────────────────────────────────────────────
echo "=== build: codex ==="
rm -rf "$ROOT/codex"
mkdir -p "$ROOT/codex/plugin/.codex-plugin"
cp -R "$SRC" "$ROOT/codex/plugin/skills"
cp -R "$PLAT/codex/skills/." "$ROOT/codex/plugin/skills/"   # agents/openai.yaml overlay
cp "$PLAT/codex/plugin.json" "$ROOT/codex/plugin/.codex-plugin/plugin.json"
cp "$PLAT/codex/README.md" "$PLAT/codex/README_KO.md" "$PLAT/codex/LICENSE" "$ROOT/codex/plugin/"

find "$ROOT/claude" "$ROOT/codex" -name ".DS_Store" -delete 2>/dev/null || true
echo "=== done → ./claude  ./codex/plugin ==="
