# Second Machine Setup

Do not copy the whole `%USERPROFILE%\.codex` directory between computers.

Use this migration model:

1. Install or copy this skill.
2. Create `%USERPROFILE%\Documents\Codex`.
3. Copy or create `external-skills.config.json`.
4. Clone external skill repositories into the configured external skills root.
5. Run `scripts/install-external-skill.ps1` for each repository, or recreate junctions manually.
6. Copy or deploy `scripts/update-external-skills.ps1` to `%USERPROFILE%\Documents\Codex\update-external-skills.ps1`.
7. Run `scripts/setup-scheduled-task.ps1` to create the Windows scheduled task.
8. Run the update script once and inspect `external-skills-update-status.txt`.
9. Restart Codex.

If usernames differ, prefer `%USERPROFILE%`-based paths and the `external-skills.config.json` file instead of hard-coded `C:\Users\<name>` paths.
