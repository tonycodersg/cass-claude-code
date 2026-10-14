#!/usr/bin/env bash
# cass doctor — runs all checks and prints a clean aligned report

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"
C_BLUE="\033[34m"
C_CYAN="\033[1;36m"
C_MAGENTA="\033[35m"

DEBUG=0
[[ "$*" == *"--debug"* ]] && DEBUG=1

PASS=0
WARN=0
FAIL=0

pass() { printf "  ${C_GREEN}✓${C_RESET}  %-22s ${C_DIM}%s${C_RESET}\n" "$1" "$2"; PASS=$((PASS+1)); }
warn() { printf "  ${C_YELLOW}⚠${C_RESET}  %-22s ${C_DIM}%s${C_RESET}\n" "$1" "$2"; WARN=$((WARN+1)); }
fail() { printf "  ${C_RED}✗${C_RESET}  %-22s ${C_DIM}%s${C_RESET}\n" "$1" "$2"; FAIL=$((FAIL+1)); }
info() { printf "  ${C_BLUE}ℹ${C_RESET}  %-22s ${C_DIM}%s${C_RESET}\n" "$1" "$2"; }
dbg()  {
  [ $DEBUG -eq 1 ] && printf "  ${C_MAGENTA}·${C_RESET}  ${C_DIM}%-22s${C_RESET} %s\n" "$1" "$2"
}

# --- version ---
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
VERSION=$(python3 -c "import json; print(json.load(open('$PLUGIN_ROOT/.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo "unknown")

printf "\n${C_CYAN}cass doctor${C_RESET}  ${C_DIM}v${VERSION}${C_RESET}"
[ $DEBUG -eq 1 ] && printf "  ${C_MAGENTA}[debug]${C_RESET}"
printf "\n${C_DIM}──────────────────────────────────────────${C_RESET}\n\n"

if [ $DEBUG -eq 1 ]; then
  printf "${C_MAGENTA}Debug info${C_RESET}\n"
  dbg "CLAUDE_PLUGIN_ROOT" "${CLAUDE_PLUGIN_ROOT:-not set}"
  dbg "resolved PLUGIN_ROOT" "$PLUGIN_ROOT"
  dbg "working dir" "$(pwd)"
  dbg "settings file" ".claude/settings.local.json $([ -f .claude/settings.local.json ] && echo '(exists)' || echo '(not found)')"
  dbg ".cass folder" "$([ -d .cass ] && echo 'exists' || echo 'not found')"
  printf "\n"
fi

# --- git identity ---
GIT_NAME=$(git config user.name 2>/dev/null)
GIT_EMAIL=$(git config user.email 2>/dev/null)
dbg "git user.name" "${GIT_NAME:-not set}"
dbg "git user.email" "${GIT_EMAIL:-not set}"
if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
  pass "git identity" "$GIT_NAME / $GIT_EMAIL"
else
  fail "git identity" "not set → git config --global user.name / user.email"
fi

# --- commit template ---
GIT_TEMPLATE=$(git config commit.template 2>/dev/null)
dbg "git commit.template" "${GIT_TEMPLATE:-not set}"
dbg ".cass/commit-template.md" "$([ -f .cass/commit-template.md ] && echo 'exists' || echo 'not found')"
if [ -f ".cass/commit-template.md" ]; then
  pass "commit template" ".cass/commit-template.md"
elif [ -f "cass-.gitmessage" ]; then
  warn "commit template" "legacy cass-.gitmessage → re-run /cass:init"
else
  info "commit template" "not set up → run /cass:init"
fi

# --- PR template ---
dbg ".cass/pr-template.md" "$([ -f .cass/pr-template.md ] && echo 'exists' || echo 'not found')"
dbg ".github/cass-pull_request_template.md" "$([ -f .github/cass-pull_request_template.md ] && echo 'exists' || echo 'not found')"
if [ -f ".cass/pr-template.md" ]; then
  pass "PR template" ".cass/pr-template.md"
elif [ -f ".github/cass-pull_request_template.md" ]; then
  warn "PR template" "legacy .github/ location → re-run /cass:init"
else
  info "PR template" "not set up → run /cass:init"
fi

printf "\n"

# --- gh installed ---
GH_VERSION=$(gh --version 2>/dev/null | head -1)
dbg "gh --version" "${GH_VERSION:-not found}"
if [ -n "$GH_VERSION" ]; then
  pass "gh" "$GH_VERSION"
else
  fail "gh" "not installed → brew install gh"
fi

# --- gh auth ---
GH_AUTH_RAW=$(gh auth status 2>&1)
GH_USER=$(echo "$GH_AUTH_RAW" | grep -i "logged in" | awk '{print $NF}' | head -1)
dbg "gh auth status" "${GH_USER:-not authenticated}"
if [ $DEBUG -eq 1 ]; then
  echo "$GH_AUTH_RAW" | head -3 | while read -r line; do dbg "  " "$line"; done
fi
if [ -n "$GH_USER" ]; then
  pass "gh auth" "logged in as $GH_USER"
else
  warn "gh auth" "not authenticated → gh auth login"
fi

printf "\n"

# --- uvx ---
UVX_VERSION=$(uvx --version 2>/dev/null)
dbg "uvx --version" "${UVX_VERSION:-not found}"
if [ -n "$UVX_VERSION" ]; then
  pass "uvx (Serena)" "$UVX_VERSION"
else
  fail "uvx (Serena)" "not installed → curl -LsSf https://astral.sh/uv/install.sh | sh"
fi

printf "\n"

# --- cass project ---
SETTINGS=".claude/settings.local.json"
dbg "settings path" "$SETTINGS $([ -f $SETTINGS ] && echo '(exists)' || echo '(not found)')"
if [ $DEBUG -eq 1 ] && [ -f "$SETTINGS" ]; then
  dbg "settings content" "$(cat $SETTINGS | tr '\n' ' ')"
fi

if [ -f "$SETTINGS" ]; then
  PROJECTS=$(python3 -c "
import json, sys
d = json.load(open('$SETTINGS'))
projects = d.get('cass', {}).get('projects', {})
for name, cfg in projects.items():
    print(f\"{name} | {cfg.get('mainRepoPath','?')} | branch: {cfg.get('mainBranch','?')} | worktrees: {cfg.get('worktreePath','?')}\")
" 2>/dev/null)
  if [ -n "$PROJECTS" ]; then
    while IFS='|' read -r name repo branch wt; do
      name=$(echo "$name" | xargs)
      repo=$(echo "$repo" | xargs)
      branch=$(echo "$branch" | xargs)
      wt=$(echo "$wt" | xargs)
      dbg "project $name worktree" "$wt $([ -d "$wt" ] && echo '(exists)' || echo '(missing)')"
      if [ -d "$wt" ]; then
        pass "project: $name" "$repo ($branch) · worktrees ✓"
      else
        warn "project: $name" "$repo ($branch) · worktrees missing → mkdir -p $wt"
      fi
    done <<< "$PROJECTS"
  else
    info "project init" "not initialised → run /cass:init"
  fi
else
  info "project init" "not initialised → run /cass:init"
fi

printf "\n${C_DIM}──────────────────────────────────────────${C_RESET}\n"
printf "  ${C_GREEN}${PASS} passed${C_RESET}  ${C_YELLOW}${WARN} warnings${C_RESET}  ${C_RED}${FAIL} failed${C_RESET}\n\n"

if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
  printf "${C_GREEN}✓ All checks passed. cass is ready to use.${C_RESET}\n\n"
fi

# machine-readable summary for Claude to reformat as its text response
printf "CASS_SUMMARY: v%s | %d passed | %d warnings | %d failed\n" "$VERSION" "$PASS" "$WARN" "$FAIL"
