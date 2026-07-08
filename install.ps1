param(
    [string] $CodexRoot = (Join-Path $env:USERPROFILE "Documents\Codex"),
    [string] $ExternalSkillsRoot = "",
    [string] $SkillsRoot = (Join-Path $env:USERPROFILE ".codex\skills"),
    [string] $RepoUrl = "https://github.com/yclinhh/codex-external-skill-manager.git",
    [string] $RepoName = "codex-external-skill-manager",
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-InstallPath {
    param(
        [Parameter(Mandatory = $true)] [string] $Path,
        [string] $BasePath = ""
    )

    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    if (-not [System.IO.Path]::IsPathRooted($expanded)) {
        if (-not $BasePath) {
            $BasePath = (Get-Location).Path
        }
        $expanded = Join-Path $BasePath $expanded
    }

    return [System.IO.Path]::GetFullPath($expanded)
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)] [string[]] $Arguments
    )

    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }
}

function Write-ExternalSkillsConfig {
    param(
        [Parameter(Mandatory = $true)] [string] $ConfigPath,
        [Parameter(Mandatory = $true)] [string] $Value
    )

    $config = [ordered]@{
        externalSkillsRoot = $Value
    }

    $json = $config | ConvertTo-Json
    Set-Content -LiteralPath $ConfigPath -Value $json -Encoding UTF8
}

Get-Command git -ErrorAction Stop | Out-Null

$CodexRoot = Resolve-InstallPath -Path $CodexRoot
$SkillsRoot = Resolve-InstallPath -Path $SkillsRoot

if ($ExternalSkillsRoot) {
    $ExternalSkillsRoot = Resolve-InstallPath -Path $ExternalSkillsRoot -BasePath $CodexRoot
    $configExternalSkillsRoot = $ExternalSkillsRoot
}
else {
    $ExternalSkillsRoot = Join-Path $CodexRoot "external-skills"
    $configExternalSkillsRoot = "external-skills"
}

$repoPath = Join-Path $ExternalSkillsRoot $RepoName
$skillTarget = Join-Path $repoPath "skills\external-skill-manager"
$linkPath = Join-Path $SkillsRoot "external-skill-manager"
$configPath = Join-Path $CodexRoot "external-skills.config.json"

Write-Host "Codex root: $CodexRoot"
Write-Host "External skills root: $ExternalSkillsRoot"
Write-Host "Codex skills root: $SkillsRoot"
Write-Host ""

New-Item -ItemType Directory -Force -Path $CodexRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ExternalSkillsRoot | Out-Null
New-Item -ItemType Directory -Force -Path $SkillsRoot | Out-Null

Write-ExternalSkillsConfig -ConfigPath $configPath -Value $configExternalSkillsRoot
Write-Host "Config written: $configPath"

if (-not (Test-Path -LiteralPath $repoPath)) {
    Write-Host "Cloning repository..."
    Invoke-Git -Arguments @("clone", $RepoUrl, $repoPath)
}
elseif (Test-Path -LiteralPath (Join-Path $repoPath ".git")) {
    Write-Host "Repository already exists; updating with git pull --ff-only..."
    Invoke-Git -Arguments @("-C", $repoPath, "fetch", "--prune")
    Invoke-Git -Arguments @("-C", $repoPath, "pull", "--ff-only")
}
else {
    throw "Target path exists but is not a Git repository: $repoPath"
}

if (-not (Test-Path -LiteralPath (Join-Path $skillTarget "SKILL.md"))) {
    throw "Skill target does not contain SKILL.md: $skillTarget"
}

if (Test-Path -LiteralPath $linkPath) {
    $existing = Get-Item -LiteralPath $linkPath
    $existingTarget = ""
    if ($existing.PSObject.Properties.Name -contains "Target") {
        $existingTarget = ($existing.Target -join ";")
    }

    if ($existing.LinkType -eq "Junction" -and $existingTarget -eq $skillTarget) {
        Write-Host "Junction already exists: $linkPath -> $skillTarget"
    }
    elseif ($Force) {
        Write-Host "Replacing existing path: $linkPath"
        Remove-Item -LiteralPath $linkPath
        New-Item -ItemType Junction -Path $linkPath -Target $skillTarget | Out-Null
        Write-Host "Junction created: $linkPath -> $skillTarget"
    }
    else {
        throw "Codex skill path already exists and points elsewhere: $linkPath. Re-run with -Force to replace it."
    }
}
else {
    New-Item -ItemType Junction -Path $linkPath -Target $skillTarget | Out-Null
    Write-Host "Junction created: $linkPath -> $skillTarget"
}

Write-Host ""
Write-Host "Installed external-skill-manager."
Write-Host 'Restart Codex, then ask Codex to run: $external-skill-manager first run'
