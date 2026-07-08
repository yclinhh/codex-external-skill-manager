# Windows Junction Notes

Use junctions for directory-to-directory links from `%USERPROFILE%\.codex\skills\<skill-name>` to a folder inside an external Git repository.

Create:

```powershell
New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.codex\skills\skill-name" `
  -Target "C:\path\to\external-skills\repo\path\to\skill"
```

Inspect:

```powershell
Get-ChildItem "$env:USERPROFILE\.codex\skills" -Directory |
  Select-Object Name, LinkType, Target
```

Delete only the junction path:

```powershell
Remove-Item "$env:USERPROFILE\.codex\skills\skill-name"
```

Do not delete the target repository unless the user explicitly asks to remove the external Git clone too.

Junctions are similar to Linux directory symlinks, but they are Windows reparse points for directories only. They are usually easier to create than Windows symbolic links and work well for Codex skill folders.
