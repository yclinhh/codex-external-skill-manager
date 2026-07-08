# Sparse Checkout For Windows Long Paths

Some repositories fail during checkout on Windows with `Filename too long`. If the repository contains a normal Codex skill folder plus very deep tests or fixtures, use sparse checkout.

Pattern:

```powershell
$repo = "C:\Users\you\Documents\Codex\external-skills\repo-name"

git clone --no-checkout https://github.com/owner/repo.git $repo
git -C $repo sparse-checkout init --no-cone
Set-Content -LiteralPath (Join-Path $repo ".git\info\sparse-checkout") -Value @(
  "/skills/skill-name/**",
  "!/skills/skill-name/tests/**",
  "!/skills/skill-name/**/fixtures/**"
) -Encoding ASCII
git -C $repo checkout
```

Adjust include and exclude patterns to preserve the actual skill files and omit only long-path test data or fixtures.

If Git reports dubious ownership when Codex reads the repository, prefer a one-command override for inspection:

```powershell
git -c safe.directory=C:/path/to/repo -C C:\path\to\repo status --short
```

Avoid changing global Git trust unless the user wants that persistent setting.
