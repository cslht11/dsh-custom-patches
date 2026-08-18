#!/bin/bash
# =============================================================================
# install-dsh-custom.sh -- DSH custom patch one-click installer
#   (enhances apply-dsh-patches.sh with version diagnosis + built-in detection)
#
# Compared to apply-dsh-patches.sh, it:
#   1. Reads local version + queries npm latest, gives version diagnosis
#   2. For each patch, checks whether the official build already contains the
#      feature (greps a marker in the target file) -- if so, skips that patch
#      to avoid duplication/conflict
#   3. backup (first time) + dry-run + apply + verify, all with colored logs
#   4. Usage: bash install-dsh-custom.sh [-y]    (-y skips interactive confirm)
#
# Adapted version: @deepseek-ai/dsh 0.1.0-rc.7 (see versions.md)
# =============================================================================
set -u

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
info() { echo -e "${CYAN}[i]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[x]${NC} $*"; }

EXPECT_VERSION="0.1.0-rc.7"

# Entries: relative plugin path | patch path in repo | built-in marker (empty = skip detection)
# If the target file already contains the marker, the feature is considered
# already present in the official build, so that patch is skipped.
FILES=(
  "dsh-host-apiproxy/lib/index.js|patches/host-apiproxy/dsh-host-apiproxy-lib-index.js.patch|editLastPrompt"
  "dsh-agent-loop/lib/index.js|patches/agent-loop/dsh-agent-loop-lib-index.js.patch|tailEvent?.type === \"user/message\""
  "dsh-client-connection/lib/client.js|patches/client-connection/dsh-client-connection-lib-client.js.patch|editLastPrompt"
  "dsh-client-runtime/lib/client.js|patches/client-runtime/dsh-client-runtime-lib-client.js.patch|editLastPrompt"
  "dsh-client-ui-conversation/lib/client.js|patches/client-ui-conversation/dsh-client-ui-conversation-lib-client.js.rc7.patch|recallHistory"
)

ASK=1
[ "${1:-}" = "-y" ] && ASK=0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}   DSH custom enhancements: one-click installer (${EXPECT_VERSION})${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# ---------- 1. locate DSH install dir ----------
info "Locating DSH install dir..."
DSH_DIR=$(node -e "try{console.log(require.resolve('@deepseek-ai/dsh/package.json').replace('/package.json',''))}catch(e){console.log('')}" 2>/dev/null)
if [ -z "$DSH_DIR" ]; then
  DSH_DIR=$(find /usr/local/lib/node_modules "$HOME/.local/lib/node_modules" -name "dsh" -path "*/@deepseek-ai/*" -type d 2>/dev/null | head -1)
fi
if [ -z "$DSH_DIR" ]; then
  err "Cannot find DSH install dir. Please install @deepseek-ai/dsh first."
  exit 1
fi
ok "Found DSH: $DSH_DIR"

# ---------- 2. version diagnosis ----------
VERSION=$(node -e "console.log(require('$DSH_DIR/package.json').version)" 2>/dev/null)
echo -e "    local version: ${YELLOW}${VERSION:-unknown}${NC}"
LATEST=$(npm view @deepseek-ai/dsh version 2>/dev/null || echo "")
if [ -n "$LATEST" ]; then
  echo -e "    npm latest:    ${YELLOW}$LATEST${NC}"
else
  warn "Cannot query npm latest (network/npm source). Continuing to apply."
fi

if [ "$VERSION" != "$EXPECT_VERSION" ]; then
  err "Version mismatch: patches target $EXPECT_VERSION, current is $VERSION"
  echo ""
  echo "  Install the matching version first:"
  echo "    npm install -g @deepseek-ai/dsh@$EXPECT_VERSION"
  echo ""
  echo "  Or if official upgraded, re-adapt per ADAPTING.md first."
  exit 1
fi
if [ -n "$LATEST" ] && [ "$LATEST" != "$EXPECT_VERSION" ]; then
  warn "Official has newer version $LATEST (patches target $EXPECT_VERSION)."
  warn "Patches may still apply; if official now bundles these features, check versions.md."
fi
echo ""

# ---------- 3. built-in detection ----------
PLUGIN_ROOT="$DSH_DIR/node_modules/@deepseek-ai"
APPLY=()     # to apply: rel|patch
SKIPPED=()   # skipped because built-in: rel|marker
echo -e "${CYAN}--- built-in detection ---${NC}"
for entry in "${FILES[@]}"; do
  rel="${entry%%|*}"; rest="${entry#*|}"; patch="${rest%%|*}"; marker="${rest#*|}"
  full="$PLUGIN_ROOT/$rel"
  if [ ! -f "$full" ]; then
    warn "Target missing, skip: $rel"
    continue
  fi
  if [ -n "$marker" ] && grep -qF "$marker" "$full" 2>/dev/null; then
    warn "Official already contains marker \"$marker\" -> skip: $rel"
    SKIPPED+=("$rel|$marker")
  else
    APPLY+=("$rel|$patch")
  fi
done

[ ${#SKIPPED[@]} -gt 0 ] && echo ""
[ ${#APPLY[@]} -eq 0 ] && { info "All features already present (built-in or applied). Nothing to do."; exit 0; }

echo ""
echo -e "${CYAN}--- patches to apply (${#APPLY[@]}) ---${NC}"
for e in "${APPLY[@]}"; do info "will apply: ${e%%|*}"; done
echo ""

if [ "$ASK" = "1" ]; then
  read -r -p "Proceed to apply the patches above? [y/N] " ans
  case "$ans" in y|Y|yes|YES) ;; *) echo "Cancelled."; exit 1 ;; esac
fi

# ---------- 4. backup + dry-run + apply + verify ----------
OK=0; FAIL=0
for entry in "${APPLY[@]}"; do
  rel="${entry%%|*}"; patch="${entry#*|}"
  full_path="$PLUGIN_ROOT/$rel"
  patch_file="$SCRIPT_DIR/$patch"

  if [ ! -f "$patch_file" ]; then
    err "Patch file missing: $patch_file"; FAIL=$((FAIL+1)); continue
  fi

  # backup (first time)
  if [ ! -f "$full_path.bak" ]; then
    cp "$full_path" "$full_path.bak" && ok "backed up: $rel.bak"
  fi

  # if already applied -> skip
  if patch --dry-run -N -p1 "$full_path" < "$patch_file" >/dev/null 2>&1; then
    if patch -N -p1 "$full_path" < "$patch_file" >/dev/null 2>&1; then
      ok "applied: $rel"; OK=$((OK+1))
    else
      err "apply failed: $rel (try: cp '$full_path.bak' '$full_path'; then rerun)"; FAIL=$((FAIL+1))
    fi
  elif patch --dry-run -N -p1 --reverse "$full_path" < "$patch_file" >/dev/null 2>&1; then
    info "already in patched state, skip: $rel"; OK=$((OK+1))
  else
    err "patch cannot apply (official may have changed the code): $rel"; FAIL=$((FAIL+1))
  fi
done

echo ""
echo -e "${CYAN}============================================================${NC}"
if [ "$FAIL" = "0" ]; then
  echo -e "${GREEN}  Done: applied/confirmed $OK patch(es), no failure.${NC}"
else
  echo -e "${RED}  Done: success $OK, failed $FAIL.${NC}"
fi
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Restart DSH: ${YELLOW}kill $(pgrep -f 'dsh web') 2>/dev/null; dsh web${NC}"
echo -e "  2. Hard-refresh the browser page (Cmd+Shift+R) to use the new features."
if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo -e "${RED}Some patches failed. Re-adapt per ADAPTING.md, or restore first:${NC}"
  echo "    for e in dsh-host-apiproxy/lib/index.js dsh-agent-loop/lib/index.js dsh-client-connection/lib/client.js dsh-client-runtime/lib/client.js dsh-client-ui-conversation/lib/client.js; do cp \"$PLUGIN_ROOT/\$e.bak\" \"$PLUGIN_ROOT/\$e\"; done"
fi
echo ""
