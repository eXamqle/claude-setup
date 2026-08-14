#!/usr/bin/env bash
#
# claude-setup bootstrap -- brings a machine up to the shared Claude Code setup.
#
#   curl -fsSL https://raw.githubusercontent.com/eXamqle/claude-setup/main/bootstrap.sh | bash
#
# Safe to re-run: it pulls the latest config, then adds/installs only what is
# missing. Run it again any time you change CLAUDE.md or plugins.txt.

set -euo pipefail

REPO_SLUG="eXamqle/claude-setup"
SETUP_DIR="${CLAUDE_SETUP_DIR:-$HOME/.claude-setup}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

if [ -t 1 ]; then
  B=$'\033[1;34m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; G=$'\033[1;32m'; N=$'\033[0m'
else
  B=""; Y=""; R=""; G=""; N=""
fi
info() { printf '%s==>%s %s\n' "$B" "$N" "$1"; }
ok()   { printf '%s  ok%s %s\n' "$G" "$N" "$1"; }
warn() { printf '%s  !!%s %s\n' "$Y" "$N" "$1" >&2; }
die()  { printf '%s  xx%s %s\n' "$R" "$N" "$1" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git is required but not installed."
command -v curl >/dev/null 2>&1 || die "curl is required but not installed."
command -v claude >/dev/null 2>&1 || die \
  "claude not found on PATH. Install Claude Code first: https://code.claude.com/docs/en/setup"

# ---------------------------------------------------------------- 1. get repo
if [ -d "$SETUP_DIR/.git" ]; then
  info "Updating $SETUP_DIR"
  git -C "$SETUP_DIR" pull --ff-only --quiet 2>/dev/null \
    || warn "could not pull (no upstream yet, or offline); using local copy"
else
  info "Cloning $REPO_SLUG into $SETUP_DIR"
  # HTTPS first: the repo is public, so this needs no keys or credentials.
  # SSH second, in case the repo is ever made private.
  git clone --quiet "https://github.com/$REPO_SLUG.git" "$SETUP_DIR" 2>/dev/null \
    || git clone --quiet "git@github.com:$REPO_SLUG.git" "$SETUP_DIR" 2>/dev/null \
    || die "clone failed. Check that github.com/$REPO_SLUG exists and is public."
fi

mkdir -p "$CLAUDE_DIR"

# ------------------------------------------------------------- 2. CLAUDE.md
# Symlinked rather than copied, so a later `git pull` updates it in place.
if [ -f "$SETUP_DIR/CLAUDE.md" ]; then
  info "Linking CLAUDE.md"
  target="$CLAUDE_DIR/CLAUDE.md"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$SETUP_DIR/CLAUDE.md" ]; then
    ok "already linked"
  else
    if [ -e "$target" ] || [ -L "$target" ]; then
      backup="$target.backup.$(date +%Y%m%d%H%M%S)"
      mv "$target" "$backup"
      warn "existing CLAUDE.md moved to $backup"
    fi
    ln -s "$SETUP_DIR/CLAUDE.md" "$target"
    ok "$target -> $SETUP_DIR/CLAUDE.md"
  fi
fi

# --------------------------------------------------------- 3. output styles
FAILED=()

if [ -f "$SETUP_DIR/output-styles.txt" ]; then
  info "Installing output styles"
  mkdir -p "$CLAUDE_DIR/output-styles"
  while read -r url _rest <&3 || [ -n "${url:-}" ]; do
    case "$url" in ''|\#*) continue ;; esac
    name="${url##*/}"
    dest="$CLAUDE_DIR/output-styles/$name"
    # Download to a temp file first, so a failed fetch can't truncate a good one.
    if curl -fsSL "$url" -o "$dest.part" 2>/dev/null; then
      mv "$dest.part" "$dest"
      ok "$name"
    else
      rm -f "$dest.part"
      warn "could not fetch $url"
      FAILED+=("$name")
    fi
  done 3< "$SETUP_DIR/output-styles.txt"
fi

# --------------------------------------------------------------- 4. plugins
MARKETPLACES=()

if [ -f "$SETUP_DIR/plugins.txt" ]; then
  info "Installing plugins"
  # Read on fd 3 and give claude </dev/null: stdin is the script itself when
  # this runs via `curl | bash`, and a child reading it would eat the rest.
  while read -r source plugin _rest <&3 || [ -n "${source:-}" ]; do
    case "$source" in ''|\#*) continue ;; esac
    [ -n "${plugin:-}" ] || { warn "skipping malformed line: $source"; continue; }

    marketplace="${plugin#*@}"
    [ "$marketplace" = "$plugin" ] && { warn "skipping '$plugin' (need plugin@marketplace)"; continue; }

    claude plugin marketplace add "$source" --scope user </dev/null >/dev/null 2>&1 || true

    if out=$(claude plugin install "$plugin" --scope user --yes </dev/null 2>&1); then
      ok "$plugin"
      MARKETPLACES+=("$marketplace")
    elif printf '%s' "$out" | grep -qi 'already installed'; then
      ok "$plugin (already installed)"
      MARKETPLACES+=("$marketplace")
    else
      warn "$plugin failed:"
      printf '%s\n' "$out" | sed 's/^/       /' >&2
      FAILED+=("$plugin")
    fi
  done 3< "$SETUP_DIR/plugins.txt"
fi

# ------------------------------------------------------------ 5. auto-update
# Third-party marketplaces default to auto-update OFF. There is no CLI flag for
# it, so patch settings.json directly. Only touches entries that already exist,
# and only the autoUpdate key.
if [ ${#MARKETPLACES[@]} -gt 0 ] && command -v python3 >/dev/null 2>&1; then
  info "Enabling marketplace auto-update"
  python3 - "$CLAUDE_DIR/settings.json" ${MARKETPLACES[@]+"${MARKETPLACES[@]}"} <<'PY' || warn "could not update settings.json"
import json, sys

path, names = sys.argv[1], sys.argv[2:]
try:
    with open(path) as f:
        data = json.load(f)
except FileNotFoundError:
    data = {}
except json.JSONDecodeError:
    sys.exit("settings.json is not valid JSON; leaving it alone")

if not isinstance(data, dict):
    sys.exit("settings.json is not a JSON object; leaving it alone")

markets = data.get("extraKnownMarketplaces")
if not isinstance(markets, dict):
    sys.exit(0)

changed = [
    n for n in names
    if isinstance(markets.get(n), dict) and markets[n].get("autoUpdate") is not True
]
for n in changed:
    markets[n]["autoUpdate"] = True

if changed:
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("  ok enabled for: " + ", ".join(changed))
else:
    print("  ok already enabled")
PY
elif [ ${#MARKETPLACES[@]} -gt 0 ]; then
  warn "python3 not found -- enable auto-update manually via /plugin > Marketplaces"
fi

# ---------------------------------------------------------------- 6. summary
echo
if [ ${#FAILED[@]} -gt 0 ]; then
  warn "Finished with ${#FAILED[@]} failure(s): ${FAILED[*]}"
  echo "  Check the marketplace name in plugins.txt against that repo's"
  echo "  .claude-plugin/marketplace.json \"name\" field."
  exit 1
fi

info "Done. Start Claude Code (or run /reload-plugins in an open session)."
echo "  Config lives in $SETUP_DIR -- edit, commit, push, then re-run this on"
echo "  your other machines."
