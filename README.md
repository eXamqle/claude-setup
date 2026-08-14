# claude-setup

Shared [Claude Code](https://code.claude.com) configuration, so every machine I
work on has the same global instructions and the same plugins.

## Bootstrap a machine

```bash
curl -sL https://raw.githubusercontent.com/eXamqle/claude-setup/main/bootstrap.sh | bash
```

That is the only thing worth memorising. It clones this repo to
`~/.claude-setup`, symlinks `CLAUDE.md` into `~/.claude/`, and installs every
plugin listed in `plugins.txt` at user scope (active in all projects).

Re-run it any time to pick up changes. It is idempotent.

> The repo must be **public** for that URL to work without a token. Keep
> anything private out of `CLAUDE.md`.

## What's here

| File           | Purpose                                                      |
| -------------- | ------------------------------------------------------------ |
| `bootstrap.sh` | Installer. Clone → link → install plugins → enable auto-update |
| `CLAUDE.md`    | Global instructions, symlinked to `~/.claude/CLAUDE.md`       |
| `plugins.txt`  | Plugins to install, one per line                              |

## Adding a plugin

Append a line to `plugins.txt`:

```
<marketplace-source>    <plugin>@<marketplace-name>
```

The marketplace name comes from that repo's `.claude-plugin/marketplace.json`
`name` field, which frequently differs from the repo name — that mismatch is the
usual cause of a failed install. Check it with:

```bash
curl -sL https://raw.githubusercontent.com/OWNER/REPO/main/.claude-plugin/marketplace.json
```

Then commit, push, and re-run the bootstrap on the other machines.

## Notes

- `~/.claude/settings.json` is deliberately **not** stored here. It sits next to
  `.credentials.json` and per-machine session state, and `claude plugin install`
  writes the `enabledPlugins` / `extraKnownMarketplaces` entries itself. The
  bootstrap only patches the `autoUpdate` flag on marketplaces it installed.
- Plugins execute arbitrary code with your user privileges. Only list sources
  you trust here — this file installs them on every machine you own.
