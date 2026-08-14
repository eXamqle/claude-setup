# Global instructions

These apply to every project on every machine. This file is loaded into context
at the start of each session, so keep it short -- everything here is a standing
token cost.

Machine-specific or project-specific rules do not belong here; put those in the
project's own `CLAUDE.md`.

## This machine's Claude Code setup

Global config (this file + the plugin list) lives in the public repo
`eXamqle/claude-setup`, cloned to `~/.claude-setup`. To sync a machine to it, or
to re-apply after editing `plugins.txt`:

```bash
curl -sL https://raw.githubusercontent.com/eXamqle/claude-setup/main/bootstrap.sh | bash
```

This repo is world-readable — never put credentials or client details in it.

## Preferences

- Prefer concrete file paths and line numbers over prose descriptions of where
  code lives.
- When a change spans several files, state the plan before editing.
