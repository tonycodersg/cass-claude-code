# Privacy Policy

**cass** is a Claude Code plugin that runs entirely on your local machine and the infrastructure you configure.

## Data collection

cass does not collect, transmit, or store any personal data, source code, or usage telemetry. All processing happens locally or through services you explicitly configure (GitHub, Jira/Atlassian, Claude API).

## Third-party services

cass integrates with third-party services only when you provide credentials and enable the integration:

- **GitHub** — PR creation, issue management, branch operations. Governed by [GitHub's Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement).
- **Atlassian** — Jira ticket reading and creation. Governed by [Atlassian's Privacy Policy](https://www.atlassian.com/legal/privacy-policy).
- **Playwright MCP** — Browser automation. All browser activity runs locally.
- **Serena MCP** — Code intelligence. Runs locally, no data is sent to external services.

## GitHub App credentials

If you configure cass-bot (optional), your GitHub App ID and private key path are stored in your local Claude Code settings (`~/.claude/settings.local.json`). The private key never leaves your machine.

## Contact

For privacy questions, open an issue at [github.com/tonycodersg/cass-claude-code](https://github.com/tonycodersg/cass-claude-code/issues).
