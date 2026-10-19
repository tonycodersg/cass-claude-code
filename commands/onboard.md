---
description: Generate a developer onboarding guide for this repo — spawns the onboarder agent to read project docs, structure, and recent activity, then writes .cass/ONBOARDING.md
allowed-tools: [Agent, Bash, Read]
model: haiku
---

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current 2>/dev/null`

## Your Role

Invoke the `onboarder` agent to generate `.cass/ONBOARDING.md` for the current repository.

## Process

Spawn the `onboarder` agent with this context:

> "Generate a developer onboarding guide for this repository.
> Read CLAUDE.md, README.md, package manifests, folder structure, cass config, and recent git activity.
> Write the guide to .cass/ONBOARDING.md.
> Report what was generated and note any sections that could not be populated."
