#!/usr/bin/env bash
# Outputs the git diff between HEAD and its merge-base against the repo's main branch.
# Tries origin/staging, origin/main, origin/master in order.
# Usage:
#   bash tools/base-diff.sh               # full diff (patch)
#   bash tools/base-diff.sh --name-only   # changed file names only
#   bash tools/base-diff.sh --stat        # diffstat

set -euo pipefail

BASE=$(git merge-base HEAD origin/staging 2>/dev/null \
  || git merge-base HEAD origin/main 2>/dev/null \
  || git merge-base HEAD origin/master 2>/dev/null \
  || { echo "base-diff.sh: no common base found with origin/staging, origin/main, or origin/master" >&2; exit 1; })

git diff "$@" "${BASE}...HEAD"
