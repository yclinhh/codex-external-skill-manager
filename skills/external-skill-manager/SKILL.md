---
name: external-skill-manager
description: Manage GitHub-backed third-party Codex skills on Windows. Use when the user asks to install an external GitHub skill, keep skills synced with GitHub, initialize or 初始配置 external skills management, create or repair junction links under .codex/skills, configure the external-skills Git directory, set up or inspect the Windows scheduled update task, move the setup to another PC, review update reports, or troubleshoot Windows long-path, sparse-checkout, safe.directory, and scheduled-task issues for Codex skills.
---

# External Skill Manager

Use this skill to manage third-party Codex skills that are stored as Git repositories and exposed to Codex through Windows junctions.

## Layout

Default layout:

```text
%USERPROFILE%\Documents\Codex\
  external-skills.config.json
  update-external-skills.ps1
  external-skills\
    repo-name\
  logs\
  external-skills-update-status.txt
  external-skills-update-latest.md

%USERPROFILE%\.codex\skills\
  skill-name -> junction to external-skills\repo-name\path\to\skill
```

Prefer this model:

1. Clone external GitHub skill repositories into the configured external skills root.
2. Link only actual skill folders containing `SKILL.md` into `%USERPROFILE%\.codex\skills`.
3. Use Windows junctions for directory links.
4. Use the update script to scan all Git repositories under the external skills root, update them, and write reports.
5. Use Windows Task Scheduler for unattended updates.

## Install A GitHub Skill

Use `scripts/install-external-skill.ps1` when the user gives a GitHub repository URL or `owner/repo`.

Process:

1. Clone the repository into the external skills root.
2. Search the cloned repository for `SKILL.md`.
3. If multiple variants exist, prefer paths containing `dist/codex/skills/` or `skills/`.
4. Avoid linking platform-specific variants such as `dist/claude`, `dist/hermes`, or `dist/openclaw` unless the user explicitly asks.
5. Create one junction per selected skill folder under `%USERPROFILE%\.codex\skills`.
6. Run the update script once to verify the repository is included in reports.
7. Tell the user to restart Codex.

If a repository has Windows long-path checkout failures, read `references/sparse-checkout-long-path.md`.

## Initialization

When the user says `初始化`, `初始配置`, `初始化外部 skills`, `first run`, or asks to set up external skills management for the first time, read `references/first-run.md` and follow it as a guided checklist.

The initialization path should verify:

1. `%USERPROFILE%\Documents\Codex` exists.
2. `external-skills.config.json` exists or should be created.
3. The external Git repository root exists.
4. `%USERPROFILE%\.codex\skills` exists.
5. Existing junctions are valid.
6. The update script exists or should be deployed from `scripts/update-external-skills.ps1`.
7. The Windows scheduled task exists or should be created with `scripts/setup-scheduled-task.ps1`.
8. A read-only list check succeeds.

## Update And Reports

Use `scripts/update-external-skills.ps1` to deploy or replace the user-level update script at `%USERPROFILE%\Documents\Codex\update-external-skills.ps1`.

The deployed update script:

- Reads `%USERPROFILE%\Documents\Codex\external-skills.config.json` when present.
- Falls back to `%USERPROFILE%\Documents\Codex\external-skills`.
- Scans immediate child directories with `.git`.
- Runs `git fetch --prune` and `git pull --ff-only`.
- Writes `external-skills-update-status.txt`.
- Writes `external-skills-update-latest.md`.
- Writes history reports under `logs/`.
- Shows a Windows popup only when a repository updated or failed.

Use `scripts/list-external-skills.ps1` to inspect existing junctions and external repositories.

## Scheduled Task

Use `scripts/setup-scheduled-task.ps1` when the user asks to create or update the Windows scheduled task.

Default task:

```text
Name: CodexUpdateExternalSkills
Schedule: Daily 09:00
Action: powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Documents\Codex\update-external-skills.ps1"
```

Keep actual scheduling in Windows Task Scheduler. Do not use Codex automations for the Git update itself unless the user explicitly asks for a Codex-level reminder or report review.

## Custom External Skills Root

The external Git repository root is configured through:

```text
%USERPROFILE%\Documents\Codex\external-skills.config.json
```

Example:

```json
{
  "externalSkillsRoot": "D:\\CodexExternalSkills"
}
```

Relative paths are resolved from `%USERPROFILE%\Documents\Codex`. Environment variables such as `%USERPROFILE%` are allowed.

When changing the external skills root, move or clone repositories into the new root and recreate affected junctions.

## Safety

- Never copy or sync the entire `%USERPROFILE%\.codex` directory across computers.
- Do not overwrite an existing skill junction or directory without checking it first.
- Treat `Remove-Item` on junctions carefully; delete only the junction path, not the target repository.
- Prefer `git pull --ff-only` for third-party repositories that the user does not modify.
- Keep third-party repositories outside `%USERPROFILE%\.codex\skills`; only junction selected skill folders into Codex.

## References

- Read `references/windows-junction.md` before explaining junctions or repairing links.
- Read `references/first-run.md` before guiding initialization or first-time setup.
- Read `references/second-machine-setup.md` before configuring another computer.
- Read `references/sparse-checkout-long-path.md` for Windows long-path checkout failures.
