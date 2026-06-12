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
#
# Build-time guards (every build — dogfood and publish both go through here):
#   ① shared references byte-identical (3 pairs)
#   ② frontmatter injection post-verified (a silent perl no-op must not ship)
#   ③ skill list discovered dynamically from src/skills/*/ (a 4th skill without
#     its claude_tools mapping or codex openai.yaml overlay fails the build)
#   ④ all 4 plugin.json versions non-empty + identical + match CHANGELOG top

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/src/skills"
PLAT="$ROOT/platform"

# ── guard ①: shared references byte-identical (pair list = the contract) ────
for pair in \
  "migration/references/harness-format.md:go/references/harness-format.md" \
  "migration/references/harness-review.md:go/references/harness-review.md" \
  "ready/references/foundation-format.md:go/references/foundation-format.md"; do
  a="$SRC/${pair%%:*}"; b="$SRC/${pair##*:}"
  if ! diff -q "$a" "$b" >/dev/null 2>&1; then
    echo "✗ shared reference drift: ${pair%%:*} ≠ ${pair##*:} — src에서 양쪽 맞춘 뒤 다시" >&2
    diff "$a" "$b" >&2 || true
    exit 1
  fi
done
echo "✓ shared references byte-identical (3 pairs)"

# ── guard ③: skills discovered dynamically from src ─────────────────────────
SKILLS=""
for d in "$SRC"/*/; do SKILLS="$SKILLS $(basename "$d")"; done
[ -n "$SKILLS" ] || { echo "✗ src/skills/ 비어 있음" >&2; exit 1; }

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
for s in $SKILLS; do
  TOOLS="$(claude_tools "$s")"
  [ -n "$TOOLS" ] || { echo "✗ claude_tools 매핑 없는 스킬: $s — build.sh claude_tools()에 추가" >&2; exit 1; }
  INJECT=$'disable-model-invocation: true\nallowed-tools: '"$TOOLS" \
    perl -0777 -i -pe 'BEGIN{$j=$ENV{INJECT}} s/\A(---\n.*?\n)---\n/$1$j\n---\n/s' \
    "$ROOT/claude/skills/$s/SKILL.md"
done
# guard ②: assert the injection actually landed (perl substitution can no-op silently)
for s in $SKILLS; do
  f="$ROOT/claude/skills/$s/SKILL.md"
  grep -q '^disable-model-invocation: true$' "$f" && grep -q '^allowed-tools: ' "$f" \
    || { echo "✗ frontmatter 주입 실패: $s — 자동실행 방지 플래그 없이 출고 불가" >&2; exit 1; }
done
cp "$PLAT/claude/plugin.json" "$ROOT/claude/.claude-plugin/plugin.json"
cp "$PLAT/claude/LICENSE" "$ROOT/claude/"

# ── Codex → ./codex/plugin ──────────────────────────────────────────────────
echo "=== build: codex ==="
rm -rf "$ROOT/codex"
mkdir -p "$ROOT/codex/plugin/.codex-plugin"
cp -R "$SRC" "$ROOT/codex/plugin/skills"
cp -R "$PLAT/codex/skills/." "$ROOT/codex/plugin/skills/"   # agents/openai.yaml overlay
# guard ③ (codex leg): every skill must carry its openai.yaml overlay
for s in $SKILLS; do
  [ -f "$ROOT/codex/plugin/skills/$s/agents/openai.yaml" ] \
    || { echo "✗ codex openai.yaml 오버레이 없는 스킬: $s — platform/codex/skills/$s/agents/ 추가" >&2; exit 1; }
done
cp "$PLAT/codex/plugin.json" "$ROOT/codex/plugin/.codex-plugin/plugin.json"
cp "$PLAT/codex/LICENSE" "$ROOT/codex/plugin/"

find "$ROOT/claude" "$ROOT/codex" -name ".DS_Store" -delete 2>/dev/null || true

# ── guard ④: version consistency ────────────────────────────────────────────
# All 4 plugin.json carry the same non-empty version AND it matches the CHANGELOG
# top entry. Catches manual-edit skew at build time instead of leaving it for a
# human (or another agent) to spot. (tag side is publish.sh's job — kept out
# here so build stays git-free.)
pj_ver() { perl -ne 'if(/"version"\s*:\s*"([^"]+)"/){print $1; last}' "$1"; }
VERS=""
for pj in "$PLAT/claude/plugin.json" "$PLAT/codex/plugin.json" \
          "$ROOT/claude/.claude-plugin/plugin.json" "$ROOT/codex/plugin/.codex-plugin/plugin.json"; do
  v="$(pj_ver "$pj")"
  [ -n "$v" ] || { echo "✗ version 비어있음: $pj" >&2; exit 1; }
  VERS="$VERS$v"$'\n'
done
UNIQ="$(printf '%s' "$VERS" | sort -u)"
if [ "$(printf '%s\n' "$UNIQ" | grep -c .)" -ne 1 ]; then
  echo "✗ version mismatch across plugin.json:" >&2
  printf '%s' "$VERS" >&2
  exit 1
fi
CL_VER="$(perl -ne 'if(/^##\s+v([0-9][^\s(]*)/){print $1; last}' "$ROOT/CHANGELOG.md")"
if [ "$UNIQ" != "$CL_VER" ]; then
  echo "✗ plugin.json=v$UNIQ but CHANGELOG top=v$CL_VER" >&2
  exit 1
fi
echo "✓ version OK: v$UNIQ (4 manifests + CHANGELOG)"

echo "=== done → ./claude  ./codex/plugin ==="
