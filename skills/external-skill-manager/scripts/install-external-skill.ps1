param(
    [Parameter(Mandatory = $true)]
    [string] $Repo,

    [string] $CodexRoot = (Join-Path $env:USERPROFILE "Documents\Codex"),
    [string] $ExternalSkillsRoot = "",
    [string[]] $SkillPath = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoUrl {
    param([string] $Value)

    if ($Value -match "^https?://") {
        return $Value
    }

    if ($Value -match "^[^/\\]+/[^/\\]+$") {
        return "https://github.com/$Value.git"
    }

    throw "Repo must be a GitHub URL or owner/repo: $Value"
}

function Get-RepoName {
    param([string] $Url)

    $leaf = Split-Path -Leaf $Url
    if ($leaf.EndsWith(".git")) {
        $leaf = $leaf.Substring(0, $leaf.Length - 4)
    }
    return $leaf
}

function Get-ConfiguredExternalRoot {
    param([string] $Root, [string] $Override)

    if ($Override) {
        return [System.IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($Override))
    }

    $configPath = Join-Path $Root "external-skills.config.json"
    $externalRoot = Join-Path $Root "external-skills"

    if (Test-Path -LiteralPath $configPath) {
        $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        if ($config.externalSkillsRoot) {
            $configuredRoot = [Environment]::ExpandEnvironmentVariables([string]$config.externalSkillsRoot)
            if (-not [System.IO.Path]::IsPathRooted($configuredRoot)) {
                $configuredRoot = Join-Path $Root $configuredRoot
            }
            $externalRoot = [System.IO.Path]::GetFullPath($configuredRoot)
        }
    }

    return $externalRoot
}

function Select-SkillDirectories {
    param(
        [string] $RepoPath,
        [string[]] $RequestedPaths
    )

    if ($RequestedPaths.Count -gt 0) {
        return @($RequestedPaths | ForEach-Object {
            $path = if ([System.IO.Path]::IsPathRooted($_)) { $_ } else { Join-Path $RepoPath $_ }
            if (-not (Test-Path -LiteralPath (Join-Path $path "SKILL.md"))) {
                throw "Requested skill path does not contain SKILL.md: $path"
            }
            [System.IO.DirectoryInfo]::new($path)
        })
    }

    $skillFiles = @(Get-ChildItem -LiteralPath $RepoPath -Recurse -Filter "SKILL.md")
    if ($skillFiles.Count -eq 0) {
        throw "No SKILL.md files found in $RepoPath"
    }

    $codex = @($skillFiles | Where-Object { $_.FullName -match "\\dist\\codex\\skills\\" })
    if ($codex.Count -gt 0) {
        return @($codex | ForEach-Object { $_.Directory })
    }

    $generic = @($skillFiles | Where-Object {
        $_.FullName -match "\\skills\\" -and
        $_.FullName -notmatch "\\dist\\(claude|hermes|openclaw)\\"
    })
    if ($generic.Count -gt 0) {
        return @($generic | ForEach-Object { $_.Directory })
    }

    if ($skillFiles.Count -eq 1) {
        return @($skillFiles[0].Directory)
    }

    throw "Multiple SKILL.md files found and no Codex/generic variant was obvious. Re-run with -SkillPath."
}

$repoUrl = Resolve-RepoUrl -Value $Repo
$repoName = Get-RepoName -Url $repoUrl
$ExternalSkillsRoot = Get-ConfiguredExternalRoot -Root $CodexRoot -Override $ExternalSkillsRoot
$repoPath = Join-Path $ExternalSkillsRoot $repoName
$skillsRoot = Join-Path $env:USERPROFILE ".codex\skills"

New-Item -ItemType Directory -Force -Path $ExternalSkillsRoot | Out-Null
New-Item -ItemType Directory -Force -Path $skillsRoot | Out-Null

if (-not (Test-Path -LiteralPath $repoPath)) {
    git clone $repoUrl $repoPath
    if ($LASTEXITCODE -ne 0) {
        throw "git clone failed for $repoUrl"
    }
}
elseif (-not (Test-Path -LiteralPath (Join-Path $repoPath ".git"))) {
    throw "Target path exists but is not a Git repository: $repoPath"
}
else {
    Write-Host "Repository already exists: $repoPath"
}

$skillDirs = Select-SkillDirectories -RepoPath $repoPath -RequestedPaths $SkillPath

foreach ($dir in $skillDirs) {
    $skillName = $dir.Name
    $linkPath = Join-Path $skillsRoot $skillName
    $targetPath = $dir.FullName

    if (Test-Path -LiteralPath $linkPath) {
        $existing = Get-Item -LiteralPath $linkPath
        $targetText = ($existing.Target -join ";")
        if ($existing.LinkType -eq "Junction" -and $targetText -eq $targetPath) {
            Write-Host "Junction already exists: $linkPath -> $targetPath"
            continue
        }
        throw "Codex skill path already exists and points elsewhere: $linkPath"
    }

    New-Item -ItemType Junction -Path $linkPath -Target $targetPath | Out-Null
    Write-Host "Linked: $linkPath -> $targetPath"
}

Write-Host "Installed $($skillDirs.Count) skill(s) from $repoUrl"
Write-Host "Restart Codex to pick up new skills."
