---
description: An example slash command — replace with your own
argument-hint: [optional-arg]
allowed-tools: [Read, Glob, Grep, Bash]
---

# Example Command

The user invoked this command with: $ARGUMENTS

## Instructions

1. Parse any arguments the user provided
2. Perform the action using the allowed tools above
3. Report results back to the user

## Context

- Working directory: !`pwd`
- Git branch: !`git branch --show-current 2>/dev/null || echo "not a git repo"`
