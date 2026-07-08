# First Run Initialization

Use this checklist when the user says `初始化`, `初始配置`, `初始化外部 skills`, `first run`, or asks to set up external skills management for the first time.

## Goal

Establish a maintainable external-skill setup:

```text
%USERPROFILE%\Documents\Codex\
  external-skills.config.json
  update-external-skills.ps1
  external-skills\
  logs\

%USERPROFILE%\.codex\skills\
  skill-name -> junction to external-skills\repo\skill-folder
```

## Checklist

1. Check `%USERPROFILE%\Documents\Codex`.
2. Check or create `%USERPROFILE%\Documents\Codex\external-skills.config.json`.
3. Resolve `externalSkillsRoot`; default to `external-skills` relative to the Codex root.
4. Check or create the resolved external skills root.
5. Check `%USERPROFILE%\.codex\skills`.
6. Deploy or verify `%USERPROFILE%\Documents\Codex\update-external-skills.ps1`.
7. Use `scripts/list-external-skills.ps1` for a read-only inventory.
8. If the user wants unattended updates, use `scripts/setup-scheduled-task.ps1`.
9. If repositories already exist, verify junctions point to real skill folders containing `SKILL.md`.
10. Tell the user to restart Codex after new or changed skills.

## Good Defaults

- Codex root: `%USERPROFILE%\Documents\Codex`
- External root: `%USERPROFILE%\Documents\Codex\external-skills`
- Scheduled task: `CodexUpdateExternalSkills`
- Schedule: daily at `09:00`
- Status file: `%USERPROFILE%\Documents\Codex\external-skills-update-status.txt`
- Latest report: `%USERPROFILE%\Documents\Codex\external-skills-update-latest.md`

## Minimal Setup Commands

Create directories:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\Documents\Codex"
New-Item -ItemType Directory -Force "$env:USERPROFILE\Documents\Codex\external-skills"
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills"
```

Create config:

```powershell
Set-Content -LiteralPath "$env:USERPROFILE\Documents\Codex\external-skills.config.json" `
  -Value '{ "externalSkillsRoot": "external-skills" }' `
  -Encoding UTF8
```

Do not create junctions until a repository has been cloned and a specific folder containing `SKILL.md` has been selected.
