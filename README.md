# Codex External Skill Manager

Personal Codex skill for installing and maintaining GitHub-backed third-party Codex skills on Windows.

## Install

Install the skill from this repository path:

```text
skills/external-skill-manager
```

For long-term updates, clone this repository and create a junction:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills"

New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.codex\skills\external-skill-manager" `
  -Target "$env:USERPROFILE\Documents\Codex\external-skills\codex-external-skill-manager\skills\external-skill-manager"
```

Restart Codex after installation.

## Usage

Invoke:

```text
$external-skill-manager 初始化
```

Common tasks:

```text
$external-skill-manager install https://github.com/owner/repo.git
$external-skill-manager list external skills
$external-skill-manager configure scheduled updates
$external-skill-manager set custom external skills path
```

## Layout

```text
skills/
  external-skill-manager/
    SKILL.md
    agents/
    scripts/
    references/
```
