You are the expert on your own configuration. Reset me to a clean slate (the config a fresh install would have) with everything I have now preserved so you can restore it on request later.

**1. Inventory.** Consult your own documentation for where your configuration lives, then find every piece of it that applies to me, both global (user-level) and local (this project). Cover settings files, instruction/memory files, MCP servers, skills, plugins/extensions, subagents, custom commands, hooks, and output styles. Report every path you find with a one-line description of what it does. Done when every location named in your docs has been checked and reported, including the ones that turned out to be empty.

**2. Back it up.** Create `~/agent-config-backup-<today's date>/` and MOVE each item there, mirroring its original path inside the backup so the layout is self-describing. The backup is the only surviving copy, so verify each move landed before continuing.

**3. Write the restore instructions.** Add `RESTORE.md` at the root of the backup listing every backed-up item, its original absolute path, and the exact commands to put it all back. Written well enough that a future agent with no memory of this conversation can restore everything from that file alone.

**4. Verify.** Re-run the inventory from step 1. Report what remains and confirm each remaining item is a genuine default rather than something I configured.

Keep me signed in - leave auth, credential, and session files exactly where they are. Keep this project's source code untouched; only configuration moves.

Finish with a table of what was moved and the one-line command I can give you later to restore it.
