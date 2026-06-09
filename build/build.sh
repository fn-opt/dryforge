#!/usr/bin/env bash
# build.sh — regenerate both platform plugins from the single canonical source.
#
#   src/skills/        canonical, platform-neutral skills (single source of truth)
#   platform/claude/   claude-only frontmatter values + plugin.json + LICENSE
#   platform/codex/    codex-only openai.yaml + plugin.json + LICENSE
#   README.md          repo-root README (+ README_KO.md) — GitHub landing only, NOT bundled into plugins
#   claude/            generated Claude plugin   (committed; Claude installs this)
#   codex/plugin/      generated Codex plugin    (committed; Codex installs this)
#
# Root marketplace manifests (.claude-plugin/marketplace.json, .agents/plugins/
# marketplace.json) are committed repo files, not build outputs.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/src/skills"
PLAT="$ROOT/platform"

# Per-skill allowed-tools for the Claude build. All three add Agent: ready dispatches the
# intent-completeness + 3-doc-gate subagents, go dispatches implementers/reviewers, and migration
# dispatches the final independent harness REVIEW subagent. bash 3.2 — no assoc arrays.
claude_tools() {
  case "$1" in
    migration|ready|go) echo "Read, Edit, Write, Bash, Grep, Glob, Agent, AskUserQuestion" ;;
  esac
}

# ── Claude → ./claude ───────────────────────────────────────────────────────
echo "=== build: claude ==="
rm -rf "$ROOT/claude"
mkdir -p "$ROOT/claude/.claude-plugin"
cp -R "$SRC" "$ROOT/claude/skills"
for s in ready go migration; do
  INJECT=$'disable-model-invocation: true\nallowed-tools: '"$(claude_tools "$s")" \
    perl -0777 -i -pe 'BEGIN{$j=$ENV{INJECT}} s/\A(---\n.*?\n)---\n/$1$j\n---\n/s' \
    "$ROOT/claude/skills/$s/SKILL.md"
done
cp "$PLAT/claude/plugin.json" "$ROOT/claude/.claude-plugin/plugin.json"
cp "$PLAT/claude/LICENSE" "$ROOT/claude/"

# ── Codex → ./codex/plugin ──────────────────────────────────────────────────
echo "=== build: codex ==="
rm -rf "$ROOT/codex"
mkdir -p "$ROOT/codex/plugin/.codex-plugin"
cp -R "$SRC" "$ROOT/codex/plugin/skills"
cp -R "$PLAT/codex/skills/." "$ROOT/codex/plugin/skills/"   # agents/openai.yaml overlay
cp "$PLAT/codex/plugin.json" "$ROOT/codex/plugin/.codex-plugin/plugin.json"
cp "$PLAT/codex/LICENSE" "$ROOT/codex/plugin/"

find "$ROOT/claude" "$ROOT/codex" -name ".DS_Store" -delete 2>/dev/null || true

# ── consistency guard ───────────────────────────────────────────────────────
# Assert the version invariant promote.sh maintains: all 4 plugin.json carry the
# same version AND it matches the CHANGELOG top entry. Catches the manual-edit
# skew at build time instead of leaving it for a human (or another agent) to spot.
# (tag side is promote.sh's job — kept out here so build stays git-free.)
pj_ver() { perl -ne 'if(/"version"\s*:\s*"([^"]+)"/){print $1; last}' "$1"; }
VERS="$(pj_ver "$PLAT/claude/plugin.json")
$(pj_ver "$PLAT/codex/plugin.json")
$(pj_ver "$ROOT/claude/.claude-plugin/plugin.json")
$(pj_ver "$ROOT/codex/plugin/.codex-plugin/plugin.json")"
UNIQ="$(printf '%s\n' "$VERS" | sort -u)"
if [ "$(printf '%s\n' "$UNIQ" | grep -c .)" -ne 1 ]; then
  echo "✗ version mismatch across plugin.json:" >&2
  printf '%s\n' "$VERS" >&2
  exit 1
fi
CL_VER="$(perl -ne 'if(/^##\s+v([0-9][^\s(]*)/){print $1; last}' "$ROOT/CHANGELOG.md")"
if [ "$UNIQ" != "$CL_VER" ]; then
  echo "✗ plugin.json=v$UNIQ but CHANGELOG top=v$CL_VER" >&2
  exit 1
fi
echo "✓ version OK: v$UNIQ (4 manifests + CHANGELOG)"

echo "=== done → ./claude  ./codex/plugin ==="
