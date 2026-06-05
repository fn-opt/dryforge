#!/usr/bin/env bash
# publish.sh — single-source release: build both platforms, validate, version, push.
# Run from anywhere: ./build/publish.sh
#
# You only ever edit src/ (and platform/ for genuinely platform-specific bits).
# This script regenerates claude/ + codex/, validates both, and publishes once.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# ── 0. branch guard — release only from main ──
# The dogfooding workflow uses local dev branches (e.g. `next`). Publishing from the wrong
# branch would commit the version bump and push/tag on that branch. Refuse anything but main.
MAIN="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
if [ -z "$MAIN" ]; then MAIN="main"; fi
CUR="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CUR" != "$MAIN" ]; then
  echo "중단: 현재 '$CUR' 브랜치 — 배포는 '$MAIN'에서만 (잘못된 브랜치 태그·push 방지)."
  echo "      git checkout $MAIN 후 재실행. (dev→release 자동화는 ../promote.sh)"
  exit 1
fi

# ── 1. ready↔set shared-reference sync ──
# Single source killed claude↔codex drift, but ready and set still carry their own
# copies of these shared references — verify they match before publishing.
echo "=== 1/6 ready↔set 동기화 검증 ==="
sync_err=0
for f in output-format.md dependency-calc.md example-3doc.md; do
  if diff -q "$ROOT/src/skills/ready/references/$f" "$ROOT/src/skills/set/references/$f" >/dev/null 2>&1; then
    echo "  ✓ $f"
  else
    echo "DRIFT: ready/$f ≠ set/$f"
    diff "$ROOT/src/skills/ready/references/$f" "$ROOT/src/skills/set/references/$f" || true
    sync_err=$((sync_err+1))
  fi
done
[ "$sync_err" -gt 0 ] && { echo "FAILED: $sync_err shared file(s) drifted — src에서 양쪽 맞춘 뒤 다시."; exit 1; }
echo ""

# ── 2. build both platforms from the single source ──
echo "=== 2/6 build (src → claude/ + codex/) ==="
bash "$ROOT/build/build.sh"
echo ""

# ── 3. validate both platforms ──
echo "=== 3/6 validate ==="
if command -v claude >/dev/null 2>&1; then
  claude plugin validate "$ROOT" >/dev/null && echo "  ✓ claude validate"
else
  echo "FAILED: claude CLI 없음 — 검증 없이 배포 불가"; exit 1
fi

VALIDATOR="$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py"
if [ -f "$VALIDATOR" ]; then
  PP=""; python3 -c 'import yaml' 2>/dev/null || PP="/private/tmp/codex-pyyaml"
  if PYTHONPATH="$PP" python3 "$VALIDATOR" "$ROOT/codex/plugin" >/dev/null 2>&1; then
    echo "  ✓ codex validate"
  else
    echo "FAILED: codex plugin validate"; PYTHONPATH="$PP" python3 "$VALIDATOR" "$ROOT/codex/plugin"; exit 1
  fi
else
  echo "FAILED: codex validator 없음 — 검증 없이 배포 불가"; exit 1
fi
echo ""

# ── 4. diff + version + commit message ──
echo "=== 4/6 changes ==="
git add -A
if git diff --cached --quiet; then
  echo "변경 사항 없음. 배포 중단."; git reset HEAD -- . >/dev/null 2>&1; exit 0
fi
git diff --cached --stat
echo ""
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "없음")
echo "현재 최신 버전: $LATEST_TAG"
read -rp "새 버전 (예: v0.3.0, 스킵하려면 엔터): " VERSION
read -rp "커밋 메시지: " COMMIT_MSG
if [ -z "$COMMIT_MSG" ]; then
  echo "커밋 메시지 비어있음. 배포 중단."; git reset HEAD -- . >/dev/null 2>&1; exit 1
fi

# guard: a staged plugin.json version with no version entered AND no matching tag would
# push a tag-less / CHANGELOG-less release. Refuse it.
PJ_VER=$(perl -ne 'if(/"version"\s*:\s*"([^"]+)"/){print $1; last}' "$ROOT/platform/claude/plugin.json")
if [ -z "$VERSION" ] && ! git rev-parse -q --verify "refs/tags/v$PJ_VER" >/dev/null 2>&1; then
  echo "중단: plugin.json=$PJ_VER 인데 v$PJ_VER 태그 없음 + 버전 미입력 → 태그·CHANGELOG 없는 릴리스 방지."
  echo "      'v$PJ_VER' 입력 후 재실행하거나 plugin.json 버전을 되돌리세요."
  git reset HEAD -- . >/dev/null 2>&1; exit 1
fi

# ── 5. version bump (both platform plugin.json + CHANGELOG), then rebuild ──
echo "=== 5/6 버전 갱신 ==="
if [ -n "$VERSION" ]; then
  NUM="${VERSION#v}"
  for pj in "$ROOT/platform/claude/plugin.json" "$ROOT/platform/codex/plugin.json"; do
    perl -i -pe "s/\"version\":\s*\"[^\"]+\"/\"version\": \"$NUM\"/" "$pj"
  done
  echo "  plugin.json (claude+codex) → $NUM"
  CHANGELOG="$ROOT/CHANGELOG.md"; DATE=$(date +%Y-%m-%d)
  ENTRY="## $VERSION ($DATE)

- $COMMIT_MSG
"
  if [ -f "$CHANGELOG" ]; then
    BODY="$(perl -0777 -pe 's/\A# Changelog\s*\n+//' "$CHANGELOG")"
    printf "# Changelog\n\n%s\n%s" "$ENTRY" "$BODY" > "$CHANGELOG.tmp" && mv "$CHANGELOG.tmp" "$CHANGELOG"
  else
    printf "# Changelog\n\n%s" "$ENTRY" > "$CHANGELOG"
  fi
  echo "  CHANGELOG → $VERSION"
  bash "$ROOT/build/build.sh" >/dev/null   # regenerate so committed outputs carry new version
  git add -A
else
  echo "  버전 스킵"
fi

git commit -q -m "$COMMIT_MSG"

# ── 6. push, then tag — push the branch first so a failed push leaves no orphan tag;
#       tag creation is idempotent so a re-run after a partial push is safe ──
echo "=== 6/6 push + 태그 ==="
git push
if [ -n "$VERSION" ]; then
  git rev-parse -q --verify "refs/tags/$VERSION" >/dev/null 2>&1 || git tag "$VERSION"
  git push origin "$VERSION"
fi

echo ""
echo "=== 배포 완료 ==="
[ -n "$VERSION" ] && echo "VERSION: $VERSION"
echo "https://github.com/fn-opt/dryforge"
