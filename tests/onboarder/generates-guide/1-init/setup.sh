#!/usr/bin/env bash
# Sets up a minimal repo with CLAUDE.md, README.md, and package.json.
# The onboarder agent must generate .cass/ONBOARDING.md with the required sections.

set -euo pipefail

git init
git config user.name "Test User"
git config user.email "test@example.com"

cat > README.md <<'EOF'
# widget-api

A REST API for managing widgets. Built with Node.js and Express, backed by PostgreSQL.

## Setup

1. Install dependencies: `npm install`
2. Copy `.env.example` to `.env` and fill in `DATABASE_URL`
3. Run migrations: `npm run migrate`
4. Start the dev server: `npm run dev`

## Tech stack

- Node.js 20 / TypeScript 5
- Express 4
- PostgreSQL via pg
- jest for tests
EOF

cat > CLAUDE.md <<'EOF'
# widget-api

## Commands
- `npm run dev` — start dev server (port 3000)
- `npm test` — run jest suite
- `npm run lint` — ESLint
- `npm run build` — compile TypeScript

## Conventions
- Feature branches from main: feat/<kebab-name>
- Semantic commits: feat/fix/chore/docs
- PRs target staging, then staging → main on release
EOF

cat > package.json <<'EOF'
{
  "name": "widget-api",
  "version": "0.1.0",
  "scripts": {
    "dev": "ts-node src/index.ts",
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src/"
  },
  "dependencies": {
    "express": "^4.18.0",
    "pg": "^8.11.0"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "typescript": "^5.0.0",
    "@types/express": "^4.17.0"
  }
}
EOF

mkdir -p src
cat > src/index.ts <<'EOF'
import express from "express";
const app = express();
app.listen(3000);
EOF

git add .
git commit -m "initial: widget-api scaffold"
git log --oneline

echo "Setup complete. Repo has README.md, CLAUDE.md, and package.json."
