#!/usr/bin/env bash
#
# scaffold-sdlc.sh — Scaffold the Copilot SDLC customization files into a target folder.
#
# Copies the .github customization (agents, instructions, prompts,
# copilot-instructions.md) as template-owned files, seeds docs/spec.md only if
# missing (project-owned state, never overwritten), and ensures src/ and tests/
# exist. Whole directories are copied, so new or renamed agents are picked up.
#
# Usage:
#   ./scripts/scaffold-sdlc.sh <target> [--from-repo <url>] [--force]
#
# Examples:
#   ./scripts/scaffold-sdlc.sh ../my-project
#   ./scripts/scaffold-sdlc.sh /code/my-project --force
#   ./scripts/scaffold-sdlc.sh ../my-project --from-repo https://github.com/MHILX/Copilot-SDLC-Demo.git

set -euo pipefail

FORCE=0
TARGET=""
FROM_REPO=""

while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    --from-repo)
      shift
      FROM_REPO="${1:-}"
      if [ -z "$FROM_REPO" ]; then
        echo "--from-repo requires a git URL" >&2
        exit 1
      fi
      ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
  shift
done

if [ -z "$TARGET" ]; then
  echo "Usage: $0 <target> [--from-repo <url>] [--force]" >&2
  exit 1
fi

# Repo root is the parent of this script's folder.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEMPLATE_SOURCES=(
  ".github/copilot-instructions.md"
  ".github/agents"
  ".github/instructions"
  ".github/prompts"
)

PROJECT_SOURCES=(
  "docs/spec.md"
)

# When --from-repo is given, clone the template into a temp folder and use that
# as the source, so a single command installs into any project.
TEMP_CLONE=""
cleanup() { [ -n "$TEMP_CLONE" ] && rm -rf "$TEMP_CLONE"; }
trap cleanup EXIT

if [ -n "$FROM_REPO" ]; then
  TEMP_CLONE="$(mktemp -d)"
  echo "Cloning template from $FROM_REPO ..."
  git clone --depth 1 "$FROM_REPO" "$TEMP_CLONE" >/dev/null 2>&1 || {
    echo "git clone failed for $FROM_REPO" >&2
    exit 1
  }
  REPO_ROOT="$TEMP_CLONE"
fi

# Verify we are running from a populated source repo.
for rel in "${TEMPLATE_SOURCES[@]}" "${PROJECT_SOURCES[@]}"; do
  if [ ! -e "$REPO_ROOT/$rel" ]; then
    echo "Source not found: $REPO_ROOT/$rel" >&2
    echo "Run from a clone of the Copilot-SDLC-Demo repo, or pass --from-repo <url>." >&2
    exit 1
  fi
done

mkdir -p "$TARGET"
TARGET_ROOT="$(cd "$TARGET" && pwd)"

echo "Scaffolding SDLC customization into: $TARGET_ROOT"

# Template-owned files: overwrite (prompting unless --force).
for rel in "${TEMPLATE_SOURCES[@]}"; do
  src="$REPO_ROOT/$rel"
  dest="$TARGET_ROOT/$rel"
  dest_parent="$(dirname "$dest")"
  mkdir -p "$dest_parent"

  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    read -r -p "Exists: $rel. Overwrite? (y/N) " answer
    case "$answer" in
      y|Y) ;;
      *) echo "  skipped   $rel"; continue ;;
    esac
  fi

  rm -rf "$dest"
  cp -R "$src" "$dest_parent/"
  echo "  copied    $rel"
done

# Project-owned files: create once, never clobber existing local state.
for rel in "${PROJECT_SOURCES[@]}"; do
  src="$REPO_ROOT/$rel"
  dest="$TARGET_ROOT/$rel"
  dest_parent="$(dirname "$dest")"
  mkdir -p "$dest_parent"

  if [ -e "$dest" ]; then
    echo "  preserved $rel (project-owned)"
    continue
  fi

  cp -R "$src" "$dest_parent/"
  echo "  copied    $rel"
done

# Ensure src/ and tests/ exist with a .gitkeep.
for dir in src tests; do
  mkdir -p "$TARGET_ROOT/$dir"
  touch "$TARGET_ROOT/$dir/.gitkeep"
  echo "  ensured $dir/"
done

echo ""
echo "Done. Next steps:"
echo "  1. Open '$TARGET_ROOT' in VS Code."
echo "  2. Reload the window so the agents are picked up."
echo "  3. Select the 'sdlc-supervisor' agent and describe what to build."
