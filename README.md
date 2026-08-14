# claude-setup

My Claude Code config, same on every machine.

## Set up a machine

```bash
curl -fsSL https://raw.githubusercontent.com/eXamqle/claude-setup/main/bootstrap.sh | bash
```

Installs the plugins and output styles, and links `CLAUDE.md` into `~/.claude/`.
Safe to re-run — that's also how you apply changes.

Output styles are installed but not switched on. Pick one with `/output-style`.

## Change something

| Want to                | Edit                |
| ---------------------- | ------------------- |
| Change global rules    | `CLAUDE.md`         |
| Add a plugin           | `plugins.txt`       |
| Add an output style    | `output-styles.txt` |

Then `git commit && git push`, and re-run the line above on the other machines.

`CLAUDE.md` is symlinked, so edits there apply immediately on this machine
without re-running anything.

**Removing** a plugin needs one extra step — the bootstrap only installs, it
never uninstalls. Delete the line, then on each machine run:

```bash
claude plugin uninstall plugin-name@marketplace-name
```

## Adding a plugin

One line in `plugins.txt`:

```
owner/repo    plugin-name@marketplace-name
```

`marketplace-name` comes from that repo's `.claude-plugin/marketplace.json`
`name` field and often differs from the repo name — that mismatch is the usual
reason an install fails. Check it:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/.claude-plugin/marketplace.json
```

## Careful

This repo is public — no credentials or client details in it. Plugins run code
with your privileges on every machine, so only list sources you trust.
